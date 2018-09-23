package formatter.marker;

import formatter.config.LineEndConfig;

class MarkLineEnds extends MarkerBase {
	public static inline var SHARP_IF:String = "if";
	public static inline var SHARP_ELSE_IF:String = "elseif";
	public static inline var SHARP_ELSE:String = "else";
	public static inline var SHARP_END:String = "end";
	public static inline var SHARP_ERROR:String = "error";

	override public function run() {
		var semicolonTokens:Array<TokenTree> = parsedCode.root.filter([Semicolon], ALL);
		for (token in semicolonTokens) {
			lineEndAfter(token);
		}

		markBrOpenClose();
		markAt();
		markDblDot();
		markSharp();
		markComments();
		markStructureExtension();
	}

	function markComments() {
		var commentTokens:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Comment(_):
					FOUND_SKIP_SUBTREE;
				case CommentLine(_):
					FOUND_SKIP_SUBTREE;
				default:
					GO_DEEPER;
			}
		});
		for (token in commentTokens) {
			switch (token.tok) {
				case CommentLine(_):
					var prev:TokenInfo = getPreviousToken(token);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(token, prev.token)) {
							noLineEndBefore(token);
						}
					}
					lineEndAfter(token);
				case Comment(_):
					var prev:TokenInfo = getPreviousToken(token);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(token, prev.token)) {
							if ((prev.whitespaceAfter == Newline) || (prev.whitespaceAfter == SpaceOrNewline)) {
								lineEndAfter(token);
							}
							noLineEndBefore(token);
						}
					}
					var commentLine:LinePos = parsedCode.getLinePos(token.pos.min);
					var prefix:String = parsedCode.getString(parsedCode.linesIdx[commentLine.line].l, token.pos.min);
					if (~/^\s*$/.match(prefix)) {
						lineEndAfter(token);
						continue;
					}
					var info:TokenInfo = getTokenInfo(token);
					if (info == null) {
						whitespace(token, Around);
					} else {
						whitespace(token, Around);
					}
				default:
			}
		}
	}

	function markBrOpenClose() {
		var brTokens:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case BrOpen:
					return FOUND_GO_DEEPER;
				default:
			}
			return GO_DEEPER;
		});

		for (brOpen in brTokens) {
			var brClose:TokenTree = brOpen.access().firstOf(BrClose).token;
			if (brClose == null) {
				continue;
			}
			var prev:TokenInfo = getPreviousToken(brOpen);
			if (prev != null) {
				switch (prev.token.tok) {
					case Dollar(name):
						if (parsedCode.isOriginalSameLine(brOpen, brClose)) {
							noLineEndAfter(brOpen);
							noLineEndBefore(brClose);
							whitespace(brOpen, None);
							whitespace(brClose, None);
							var next:TokenInfo = getNextToken(brClose);
							if (next != null) {
								switch (next.token.tok) {
									case DblDot:
										whitespace(brClose, After);
									default:
								}
							}
							continue;
						}
						if (name.length <= 1) {
							whitespace(brOpen, NoneBefore);
						}
					default:
				}
			}
			var next:TokenInfo = getNextToken(brOpen);
			var isEmpty:Bool = false;
			if ((next != null) && next.token.is(BrClose) && (config.lineEnds.emptyCurly == NoBreak)) {
				isEmpty = true;
			}
			if (!isEmpty) {
				switch (config.lineEnds.leftCurly) {
					case None:
					case Before:
						beforeLeftCurly(brOpen);
					case After:
						lineEndAfter(brOpen);
					case Both:
						beforeLeftCurly(brOpen);
						lineEndAfter(brOpen);
				}
			}

			var preventBefore:Bool = false;
			if (isEmpty) {
				preventBefore = true;
			}
			switch (config.lineEnds.rightCurly) {
				case None:
				case Before:
					if (!preventBefore) {
						beforeRightCurly(brClose);
					}
				case After:
					afterRightCurly(brClose);
				case Both:
					if (!preventBefore) {
						beforeRightCurly(brClose);
					}
					afterRightCurly(brClose);
			}
		}
	}

	function beforeLeftCurly(token:TokenTree) {
		var prevToken:TokenInfo = getPreviousToken(token);
		if (prevToken == null) {
			return;
		}
		switch (prevToken.token.tok) {
			default:
				switch (prevToken.whitespaceAfter) {
					case None:
						prevToken.whitespaceAfter = Newline;
					case Newline:
					case Space:
						prevToken.whitespaceAfter = SpaceOrNewline;
					case SpaceOrNewline:
				}
		}
	}

	function beforeRightCurly(token:TokenTree) {
		var prevToken:TokenInfo = getPreviousToken(token);
		if (prevToken == null) {
			return;
		}
		switch (prevToken.whitespaceAfter) {
			case None:
				prevToken.whitespaceAfter = Newline;
			case Newline:
			case Space:
				prevToken.whitespaceAfter = SpaceOrNewline;
			case SpaceOrNewline:
		}
	}

	function afterRightCurly(token:TokenTree) {
		var next:Int = token.index + 1;
		if (parsedCode.tokenList.tokens.length <= next) {
			lineEndAfter(token);
			return;
		}
		var nextToken:TokenInfo = getTokenAt(next);
		if (nextToken == null) {
			lineEndAfter(token);
			return;
		}
		switch (nextToken.token.tok) {
			case PClose:
			case Dot:
			case Comma:
			case Semicolon:
			case Arrow:
			case Binop(OpAssign):
			default:
				lineEndAfter(token);
		}
	}

	function markAt() {
		var atTokens:Array<TokenTree> = parsedCode.root.filter([At], ALL);
		for (token in atTokens) {
			var metadataPolicy:AtLineEndPolicy = determineMetadataPolicy(token);
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token);
			if (lastChild == null) {
				continue;
			}
			if (metadataPolicy == After) {
				lineEndAfter(lastChild);
				continue;
			}
			if ((token.previousSibling != null) && (token.previousSibling.is(At))) {
				// only look at first metadata
				continue;
			}
			var next:TokenTree = token.nextSibling;
			var metadata:Array<TokenTree> = [token];
			while ((next != null) && (next.is(At))) {
				metadata.push(next);
				next = next.nextSibling;
			}
			for (meta in metadata) {
				lastChild = TokenTreeCheckUtils.getLastToken(meta);
				if (lastChild == null) {
					continue;
				}
				switch (metadataPolicy) {
					case None:
						var next:TokenInfo = getNextToken(lastChild);
						if ((next != null) && (!parsedCode.isOriginalSameLine(lastChild, next.token))) {
							lineEndAfter(lastChild);
							continue;
						}
						whitespace(lastChild, After);
					case After:
						lineEndAfter(lastChild);
					case AfterLast:
						var next:TokenInfo = getNextToken(lastChild);
						if ((next != null) && (!parsedCode.isOriginalSameLine(lastChild, next.token))) {
							lineEndAfter(lastChild);
							continue;
						}
						whitespace(lastChild, After);
					case ForceAfterLast:
						whitespace(lastChild, After);
				}
			}
			if ((metadataPolicy == AfterLast) || (metadataPolicy == ForceAfterLast)) {
				lineEndAfter(lastChild);
			}
		}
	}

	function determineMetadataPolicy(token:TokenTree):AtLineEndPolicy {
		if (token == null) {
			return config.lineEnds.metadataOther;
		}
		var parent:TokenTree = token.parent;
		if ((parent == null) || (parent.tok == null)) {
			return config.lineEnds.metadataType;
		}
		switch (parent.tok) {
			case Const(CIdent(_)), Kwd(KwdNew), Dollar(_):
				switch (parent.parent.tok) {
					case Kwd(KwdVar):
						return config.lineEnds.metadataVar;
					case Kwd(KwdFunction):
						return config.lineEnds.metadataFunction;
					case Kwd(KwdAbstract), Kwd(KwdClass), Kwd(KwdEnum), Kwd(KwdInterface), Kwd(KwdTypedef):
						return config.lineEnds.metadataType;
					default:
						return config.lineEnds.metadataOther;
				}
			case Kwd(KwdFunction):
				return config.lineEnds.metadataFunction;
			case Sharp(_):
				return After;
			default:
				return config.lineEnds.metadataOther;
		}
	}

	function markDblDot() {
		var dblDotTokens:Array<TokenTree> = parsedCode.root.filter([DblDot], ALL);
		for (token in dblDotTokens) {
			if (!token.parent.is(Kwd(KwdCase)) && !token.parent.is(Kwd(KwdDefault))) {
				continue;
			}

			if (config.lineEnds.caseColon != None) {
				lineEndAfter(token);
			}
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token);
			if (lastChild == null) {
				continue;
			}
			lineEndAfter(lastChild);
		}
	}

	function markSharp() {
		var sharpTokens:Array<TokenTree> = parsedCode.root.filter([
			Sharp(SHARP_IF),
			Sharp(SHARP_ELSE),
			Sharp(SHARP_ELSE_IF),
			Sharp(SHARP_END),
			Sharp("error")
		], ALL);
		for (token in sharpTokens) {
			switch (token.tok) {
				case Sharp(SHARP_IF), Sharp(SHARP_ELSE_IF):
					var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token.getFirstChild());
					if (lastChild == null) {
						continue;
					}
					if (config.lineEnds.sharp == None) {
						whitespace(lastChild, After);
						continue;
					}
					if (isInlineSharp(token)) {
						if (token.is(Sharp(SHARP_IF)) && isOnlyWhitespaceBeforeToken(token)) {
							continue;
						}
						var prev:TokenInfo = getPreviousToken(token);
						if (prev == null) {
							noLineEndBefore(token);
						} else {
							switch (prev.token.tok) {
								case POpen, BrOpen, BkOpen, Dot, DblDot:
									whitespace(token, NoneBefore);
								default:
									noLineEndBefore(token);
							}
						}
						continue;
					}
					lineEndBefore(token);
					lineEndAfter(lastChild);
				case Sharp(SHARP_ELSE):
					if (isInlineSharp(token)) {
						noLineEndBefore(token);
						continue;
					}
					lineEndBefore(token);
					lineEndAfter(token);
				case Sharp(SHARP_END):
					if (isInlineSharp(token)) {
						noLineEndBefore(token);
						var next:TokenInfo = getNextToken(token);
						if ((next != null) && next.token.is(Semicolon)) {
							whitespace(token, NoneAfter);
							continue;
						}
						if (!isOnlyWhitespaceAfterToken(token)) {
							continue;
						}
					} else {
						lineEndBefore(token);
					}
					lineEndAfter(token);
				case Sharp("error"):
					var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token.getFirstChild());
					if (lastChild == null) {
						lastChild = token;
					}
					lineEndAfter(lastChild);
				default:
					lineEndAfter(token);
			}
		}
	}

	function isInlineSharp(token:TokenTree):Bool {
		switch (token.tok) {
			case Sharp(SHARP_IF):
				var sharpEnd:TokenTree = token.getLastChild();
				if (sharpEnd == null) {
					return false;
				}
				switch (sharpEnd.tok) {
					case Sharp(SHARP_END):
					case Semicolon:
						sharpEnd = sharpEnd.previousSibling;
						if (sharpEnd == null) {
							return false;
						}
						if (!sharpEnd.is(Sharp(SHARP_END))) {
							return false;
						}
					default:
						return false;
				}
				var prev:TokenInfo = getPreviousToken(token);
				if ((prev != null) && prev.token.is(Semicolon)) {
					return false;
				}
				if (!isOnlyWhitespaceAfterToken(sharpEnd)) {
					return true;
				}
				if (!isOnlyWhitespaceBeforeToken(token)) {
					return true;
				}
				var prev:TokenInfo = getPreviousToken(token);
				if (prev == null) {
					return !isOnlyWhitespaceBeforeToken(token);
				}
				if ((prev.whitespaceAfter == Newline) || (prev.whitespaceAfter == SpaceOrNewline)) {
					return false;
				}
				switch (prev.token.tok) {
					case Semicolon:
						return false;
					case BrClose:
						return false;
					case Comment(_), CommentLine(_):
						return false;
					default:
						return true;
				}
			case Sharp(SHARP_ELSE):
				return isInlineSharp(token.parent);
			case Sharp(SHARP_ELSE_IF):
				return isInlineSharp(token.parent);
			case Sharp(SHARP_END):
				return isInlineSharp(token.parent);
			default:
				return false;
		}
	}

	function isOnlyWhitespaceBeforeToken(token:TokenTree):Bool {
		var tokenLine:LinePos = parsedCode.getLinePos(token.pos.min);
		var prefix:String = parsedCode.getString(parsedCode.linesIdx[tokenLine.line].l, token.pos.min);
		return (~/^\s*$/.match(prefix));
	}

	function isOnlyWhitespaceAfterToken(token:TokenTree):Bool {
		var tokenLine:LinePos = parsedCode.getLinePos(token.pos.max);
		var prefix:String = parsedCode.getString(token.pos.max, parsedCode.linesIdx[tokenLine.line].r);
		return (~/^\s*$/.match(prefix));
	}

	function findTypedefBrOpen(token:TokenTree):TokenTree {
		var assign:TokenTree = token.access().firstChild().isCIdent().firstOf(Binop(OpAssign)).token;
		if (assign == null) {
			return null;
		}
		return assign.access().firstOf(BrOpen).token;
	}

	function markStructureExtension() {
		var typedefTokens:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdTypedef)], ALL);
		for (token in typedefTokens) {
			markAfterTypedef(token);
			var brOpen:TokenTree = findTypedefBrOpen(token);
			if (brOpen == null) {
				continue;
			}
			if ((brOpen.children == null) || (brOpen.children.length <= 0)) {
				continue;
			}
			var assignParent:TokenTree = brOpen.parent;
			if (assignParent.children.length > 1) {
				for (child in assignParent.children) {
					var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
					if (lastChild == null) {
						continue;
					}
					var next:TokenInfo = getNextToken(lastChild);
					if (next == null) {
						continue;
					}
					if (lastChild.is(BrClose)) {
						switch (next.token.tok) {
							case Arrow:
								whitespace(lastChild, None);
								continue;
							case Binop(OpAnd):
								noLineEndAfter(lastChild);
								continue;
							case Semicolon:
								whitespace(lastChild, NoneAfter);
								continue;
							default:
						}
					}
					if (next.token.is(BrOpen)) {
						continue;
					}
					lineEndAfter(lastChild);
				}
			}

			for (child in brOpen.children) {
				switch (child.tok) {
					case Binop(OpGt), Const(CIdent(_)), Question:
						var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
						if (lastChild == null) {
							continue;
						}
						lineEndAfter(lastChild);
					case BrClose:
						var next:TokenInfo = getNextToken(child);
						if (next == null) {
							continue;
						}
						if (next.token.is(Binop(OpAnd))) {
							noLineEndAfter(child);
						}
						if (next.token.is(Binop(OpGt))) {
							whitespace(child, NoneAfter);
						}
					default:
				}
			}
		}
	}

	function markAfterTypedef(token:TokenTree) {
		var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token);
		if (lastChild == null) {
			return;
		}
		var next:TokenInfo = getNextToken(lastChild);
		if ((next != null) && next.token.is(Semicolon)) {
			whitespace(lastChild, NoneAfter);
			return;
		}
		lineEndAfter(lastChild);
	}
}
