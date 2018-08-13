package formatter.marker;

import formatter.config.LineEndConfig;

class MarkLineEnds {
	public static inline var SHARP_IF:String = "if";
	public static inline var SHARP_ELSE_IF:String = "elseif";
	public static inline var SHARP_ELSE:String = "else";
	public static inline var SHARP_END:String = "end";
	public static inline var SHARP_ERROR:String = "error";

	public static function markLineEnds(parsedCode:ParsedCode, config:LineEndConfig) {
		var semicolonTokens:Array<TokenTree> = parsedCode.root.filter([Semicolon], ALL);
		for (token in semicolonTokens) {
			parsedCode.tokenList.lineEndAfter(token);
		}

		markBrOpenClose(parsedCode, config);
		markAt(parsedCode, config);
		markDblDot(parsedCode, config);
		markSharp(parsedCode, config);
		markComments(parsedCode, config);
		markStructureExtension(parsedCode, config);
	}

	static function markComments(parsedCode:ParsedCode, config:LineEndConfig) {
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
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(token, prev.token)) {
							parsedCode.tokenList.noLineEndBefore(token);
						}
					}
					parsedCode.tokenList.lineEndAfter(token);
				case Comment(_):
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(token, prev.token)) {
							if (prev.whitespaceAfter == Newline) {
								parsedCode.tokenList.lineEndAfter(token);
							}
							parsedCode.tokenList.noLineEndBefore(token);
						}
					}
					var commentLine:LinePos = parsedCode.getLinePos(token.pos.min);
					var prefix:String = parsedCode.getString(parsedCode.linesIdx[commentLine.line].l, token.pos.min);
					if (~/^\s*$/.match(prefix)) {
						parsedCode.tokenList.lineEndAfter(token);
						continue;
					}
					var info:TokenInfo = parsedCode.tokenList.getTokenAt(token.index);
					if (info == null) {
						parsedCode.tokenList.whitespace(token, Around);
					} else {
						if (info.whitespaceAfter == Newline) {
							parsedCode.tokenList.whitespace(token, Before);
						} else {
							parsedCode.tokenList.whitespace(token, Around);
						}
					}
				default:
			}
		}
	}

	static function markBrOpenClose(parsedCode:ParsedCode, config:LineEndConfig) {
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
			var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(brOpen);
			if (prev != null) {
				switch (prev.token.tok) {
					case Dollar(name):
						if (parsedCode.isOriginalSameLine(brOpen, brClose)) {
							parsedCode.tokenList.whitespace(brOpen, None);
							parsedCode.tokenList.whitespace(brClose, None);
							continue;
						}
						if (name.length <= 1) {
							parsedCode.tokenList.whitespace(brOpen, NoneBefore);
						}
					case Kwd(KwdMacro):
						if (parsedCode.isOriginalSameLine(brOpen, brClose)) {
							parsedCode.tokenList.whitespace(brOpen, NoneAfter);
							parsedCode.tokenList.whitespace(brClose, NoneBefore);
							continue;
						}
					default:
				}
			}
			var next:TokenInfo = parsedCode.tokenList.getNextToken(brOpen);
			var isEmpty:Bool = false;
			if ((next != null) && next.token.is(BrClose) && (config.emptyCurly == NoBreak)) {
				isEmpty = true;
			}
			if (!isEmpty) {
				switch (config.leftCurly) {
					case None:
					case Before:
						beforeLeftCurly(brOpen, parsedCode);
					case After:
						parsedCode.tokenList.lineEndAfter(brOpen);
					case Both:
						beforeLeftCurly(brOpen, parsedCode);
						parsedCode.tokenList.lineEndAfter(brOpen);
				}
			}

			var preventBefore:Bool = false;
			var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(brClose);
			if (isEmpty) {
				preventBefore = true;
			}
			switch (config.rightCurly) {
				case None:
				case Before:
					if (!preventBefore) {
						beforeRightCurly(brClose, parsedCode);
					}
				case After:
					afterRightCurly(brClose, parsedCode);
				case Both:
					if (!preventBefore) {
						beforeRightCurly(brClose, parsedCode);
					}
					afterRightCurly(brClose, parsedCode);
			}
		}
	}

	static function beforeLeftCurly(token:TokenTree, parsedCode:ParsedCode) {
		var prevToken:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if (prevToken == null) {
			return;
		}
		switch (prevToken.token.tok) {
			default:
				prevToken.whitespaceAfter = Newline;
		}
	}

	static function beforeRightCurly(token:TokenTree, parsedCode:ParsedCode) {
		var prevToken:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if (prevToken == null) {
			return;
		}
		prevToken.whitespaceAfter = Newline;
	}

	static function afterRightCurly(token:TokenTree, parsedCode:ParsedCode) {
		var next:Int = token.index + 1;
		if (parsedCode.tokenList.tokens.length <= next) {
			parsedCode.tokenList.lineEndAfter(token);
			return;
		}
		var nextToken:TokenInfo = parsedCode.tokenList.getTokenAt(next);
		if (nextToken == null) {
			parsedCode.tokenList.lineEndAfter(token);
			return;
		}
		switch (nextToken.token.tok) {
			case PClose:
			case Comma:
			case Semicolon:
			case Binop(OpAssign):
			default:
				parsedCode.tokenList.lineEndAfter(token);
		}
	}

	static function markAt(parsedCode:ParsedCode, config:LineEndConfig) {
		var atTokens:Array<TokenTree> = parsedCode.root.filter([At], ALL);
		for (token in atTokens) {
			var metadataPolicy:AtLineEndPolicy = determineMetadataPolicy(token, config);
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token);
			if (lastChild == null) {
				continue;
			}
			if (metadataPolicy == After) {
				parsedCode.tokenList.lineEndAfter(lastChild);
				continue;
			}
			if ((token.previousSibling != null) && (token.previousSibling.is(At))) {
				// only look at first metadata
				continue;
			}
			var totalLength:Int = parsedCode.tokenList.calcLength(token) + 1;
			var next:TokenTree = token.nextSibling;
			var metadata:Array<TokenTree> = [token];
			while ((next != null) && (next.is(At))) {
				totalLength += parsedCode.tokenList.calcLength(next) + 1;
				metadata.push(next);
				next = next.nextSibling;
			}
			if (totalLength > config.maxMetadataLength) {
				metadataPolicy = After;
			}
			for (meta in metadata) {
				lastChild = TokenTreeCheckUtils.getLastToken(meta);
				if (lastChild == null) {
					continue;
				}
				switch (metadataPolicy) {
					case None:
						parsedCode.tokenList.whitespace(lastChild, After);
					case After:
						parsedCode.tokenList.lineEndAfter(lastChild);
					case AfterLast:
						parsedCode.tokenList.whitespace(lastChild, After);
				}
			}
			if (metadataPolicy == AfterLast) {
				parsedCode.tokenList.lineEndAfter(lastChild);
			}
		}
	}

	static function determineMetadataPolicy(token:TokenTree, config:LineEndConfig):AtLineEndPolicy {
		if (token == null) {
			return config.metadataOther;
		}
		var parent:TokenTree = token.parent;
		if ((parent == null) || (parent.tok == null)) {
			return config.metadataType;
		}
		switch (parent.tok) {
			case Const(CIdent(_)), Kwd(KwdNew), Dollar(_):
				switch (parent.parent.tok) {
					case Kwd(KwdVar):
						return config.metadataVar;
					case Kwd(KwdFunction):
						return config.metadataFunction;
					case Kwd(KwdAbstract), Kwd(KwdClass), Kwd(KwdEnum), Kwd(KwdInterface), Kwd(KwdTypedef):
						return config.metadataType;
					default:
						return config.metadataOther;
				}
			case Kwd(KwdFunction):
				return config.metadataFunction;
			case Sharp(_):
				return After;
			default:
				return config.metadataOther;
		}
	}

	static function markDblDot(parsedCode:ParsedCode, config:LineEndConfig) {
		var dblDotTokens:Array<TokenTree> = parsedCode.root.filter([DblDot], ALL);
		for (token in dblDotTokens) {
			if (!token.parent.is(Kwd(KwdCase)) && !token.parent.is(Kwd(KwdDefault))) {
				continue;
			}

			if (config.caseColon != None) {
				parsedCode.tokenList.lineEndAfter(token);
			}
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token);
			if (lastChild == null) {
				continue;
			}
			parsedCode.tokenList.lineEndAfter(lastChild);
		}
	}

	static function markSharp(parsedCode:ParsedCode, config:LineEndConfig) {
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
					if (config.sharp == None) {
						parsedCode.tokenList.whitespace(lastChild, After);
						continue;
					}
					if (isInlineSharp(token, parsedCode)) {
						if (token.is(Sharp(SHARP_IF)) && isOnlyWhitespaceBeforeToken(token, parsedCode)) {
							continue;
						}
						var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
						if (prev == null) {
							parsedCode.tokenList.noLineEndBefore(token);
						} else {
							switch (prev.token.tok) {
								case POpen, BrOpen, BkOpen, Dot, DblDot:
									parsedCode.tokenList.whitespace(token, NoneBefore);
								default:
									parsedCode.tokenList.noLineEndBefore(token);
							}
						}
						continue;
					}
					parsedCode.tokenList.lineEndBefore(token);
					parsedCode.tokenList.lineEndAfter(lastChild);
				case Sharp(SHARP_ELSE):
					if (isInlineSharp(token, parsedCode)) {
						parsedCode.tokenList.noLineEndBefore(token);
						continue;
					}
					parsedCode.tokenList.lineEndBefore(token);
					parsedCode.tokenList.lineEndAfter(token);
				case Sharp(SHARP_END):
					if (isInlineSharp(token, parsedCode)) {
						parsedCode.tokenList.noLineEndBefore(token);
						var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
						if ((next != null) && next.token.is(Semicolon)) {
							parsedCode.tokenList.whitespace(token, NoneAfter);
							continue;
						}
						if (!isOnlyWhitespaceAfterToken(token, parsedCode)) {
							continue;
						}
					} else {
						parsedCode.tokenList.lineEndBefore(token);
					}
					parsedCode.tokenList.lineEndAfter(token);
				case Sharp("error"):
					var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token.getFirstChild());
					if (lastChild == null) {
						lastChild = token;
					}
					parsedCode.tokenList.lineEndAfter(lastChild);
				default:
					parsedCode.tokenList.lineEndAfter(token);
			}
		}
	}

	static function isInlineSharp(token:TokenTree, parsedCode:ParsedCode):Bool {
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
				if (!isOnlyWhitespaceAfterToken(sharpEnd, parsedCode)) {
					return true;
				}
				var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
				if (prev == null) {
					return !isOnlyWhitespaceBeforeToken(token, parsedCode);
				}
				if (prev.whitespaceAfter == Newline) {
					return false;
				}
				switch (prev.token.tok) {
					case Semicolon:
						return false;
					case BrClose:
						return false;
					default:
						return true;
				}
			case Sharp(SHARP_ELSE):
				return isInlineSharp(token.parent, parsedCode);
			case Sharp(SHARP_ELSE_IF):
				return isInlineSharp(token.parent, parsedCode);
			case Sharp(SHARP_END):
				return isInlineSharp(token.parent, parsedCode);
			default:
				return false;
		}
	}

	static function isOnlyWhitespaceBeforeToken(token:TokenTree, parsedCode:ParsedCode):Bool {
		var tokenLine:LinePos = parsedCode.getLinePos(token.pos.min);
		var prefix:String = parsedCode.getString(parsedCode.linesIdx[tokenLine.line].l, token.pos.min);
		return (~/^\s*$/.match(prefix));
	}

	static function isOnlyWhitespaceAfterToken(token:TokenTree, parsedCode:ParsedCode):Bool {
		var tokenLine:LinePos = parsedCode.getLinePos(token.pos.max);
		var prefix:String = parsedCode.getString(token.pos.max, parsedCode.linesIdx[tokenLine.line].r);
		return (~/^\s*$/.match(prefix));
	}

	static function findTypedefBrOpen(token:TokenTree):TokenTree {
		var assign:TokenTree = token.access().firstChild().isCIdent().firstOf(Binop(OpAssign)).token;
		if (assign == null) {
			return null;
		}
		var brOpen:TokenTree = assign.getFirstChild();
		while (brOpen != null) {
			switch (brOpen.tok) {
				case BrOpen:
					return brOpen;
				case Const(CIdent(_)):
					brOpen = brOpen.getLastChild();
				case Binop(OpAnd):
					brOpen = brOpen.getFirstChild();
				default:
					return null;
			}
		}
		return null;
	}

	static function markStructureExtension(parsedCode:ParsedCode, config:LineEndConfig) {
		var typedefTokens:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdTypedef)], ALL);
		for (token in typedefTokens) {
			markAfterTypedef(token, parsedCode);
			var brOpen:TokenTree = findTypedefBrOpen(token);
			if (brOpen == null) {
				continue;
			}
			if ((brOpen.children == null) || (brOpen.children.length <= 0)) {
				continue;
			}
			for (child in brOpen.children) {
				switch (child.tok) {
					case Binop(OpGt), Const(CIdent(_)), Question:
						var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
						if (lastChild == null) {
							continue;
						}
						parsedCode.tokenList.lineEndAfter(lastChild);
					case BrClose:
						var next:TokenInfo = parsedCode.tokenList.getNextToken(child);
						if (next == null) {
							continue;
						}
						if (next.token.is(Binop(OpAnd))) {
							parsedCode.tokenList.noLineEndAfter(child);
						}
						if (next.token.is(Binop(OpGt))) {
							parsedCode.tokenList.whitespace(child, NoneAfter);
						}
					default:
				}
			}
		}
	}

	static function markAfterTypedef(token:TokenTree, parsedCode:ParsedCode) {
		var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token);
		if (lastChild == null) {
			return;
		}
		var next:TokenInfo = parsedCode.tokenList.getNextToken(lastChild);
		if ((next != null) && next.token.is(Semicolon)) {
			parsedCode.tokenList.whitespace(lastChild, NoneAfter);
			return;
		}
		parsedCode.tokenList.lineEndAfter(lastChild);
	}
}
