package formatter.marker;

import formatter.config.LineEndConfig;

class MarkLineEnds {
	public static inline var SHARP_IF:String = "if";
	public static inline var SHARP_ELSE_IF:String = "elseif";
	public static inline var SHARP_ELSE:String = "else";
	public static inline var SHARP_END:String = "end";

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
					var commentLine:Int = parsedCode.getLinePos(token.pos.min).line;
					var prevLine:Int = -1;
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
					if (prev != null) {
						prevLine = parsedCode.getLinePos(prev.token.pos.min).line;
					}
					if (prevLine == commentLine) {
						parsedCode.tokenList.noLineEndBefore(token);
					}
					parsedCode.tokenList.lineEndAfter(token);
				case Comment(_):
					var commentLine:LinePos = parsedCode.getLinePos(token.pos.min);
					var prefix:String = parsedCode.getString(parsedCode.linesIdx[commentLine.line].l, token.pos.min);
					if (~/^\s*$/.match(prefix)) {
						parsedCode.tokenList.lineEndAfter(token);
						continue;
					}
					parsedCode.tokenList.whitespace(token, Around);
				default:
			}
		}
	}

	static function markBrOpenClose(parsedCode:ParsedCode, config:LineEndConfig) {
		var brTokens:Array<TokenTree> = parsedCode.root.filter([BrOpen, BrClose], ALL);
		for (token in brTokens) {
			switch (token.tok) {
				case BrOpen:
					var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
					if ((next != null) && next.token.is(BrClose) && (config.emptyCurly == NoBreak)) {
						continue;
					}
					switch (config.leftCurly) {
						case None:
						case Before:
							beforeLeftCurly(token, parsedCode);
						case After:
							parsedCode.tokenList.lineEndAfter(token);
						case Both:
							beforeLeftCurly(token, parsedCode);
							parsedCode.tokenList.lineEndAfter(token);
					}
				case BrClose:
					var preventBefore:Bool = false;
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
					if ((prev != null) && prev.token.is(BrOpen) && (config.emptyCurly == NoBreak)) {
						preventBefore = true;
					}
					switch (config.rightCurly) {
						case None:
						case Before:
							if (!preventBefore) {
								beforeRightCurly(token, parsedCode);
							}
						case After:
							afterRightCurly(token, parsedCode);
						case Both:
							if (!preventBefore) {
								beforeRightCurly(token, parsedCode);
							}
							afterRightCurly(token, parsedCode);
					}
				default:
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
			default:
				parsedCode.tokenList.lineEndAfter(token);
		}
	}

	static function markAt(parsedCode:ParsedCode, config:LineEndConfig) {
		var atTokens:Array<TokenTree> = parsedCode.root.filter([At], ALL);
		for (token in atTokens) {
			var atPolicy:AtLineEndPolicy = determineAtPolicy(token, config);
			var lastChild:TokenTree = lastToken(token);
			if (lastChild == null) {
				continue;
			}
			if (atPolicy == None) {
				parsedCode.tokenList.whitespace(lastChild, After);
				continue;
			}

			if (atPolicy == AfterLast) {
				var sibling:TokenTree = token.nextSibling;
				if ((sibling != null) && (sibling.is(At))) {
					parsedCode.tokenList.whitespace(lastChild, After);
					continue;
				}
			}
			parsedCode.tokenList.lineEndAfter(lastChild);
		}
	}

	static function determineAtPolicy(token:TokenTree, config:LineEndConfig):AtLineEndPolicy {
		if (token == null) {
			return config.atOther;
		}
		var parent:TokenTree = token.parent.parent;
		if ((parent == null) || (parent.tok == null)) {
			return config.atType;
		}
		switch (parent.tok) {
			case Kwd(KwdVar):
				return config.atVar;
			case Kwd(KwdFunction):
				return config.atFunction;
			case Kwd(KwdAbstract), Kwd(KwdClass), Kwd(KwdEnum), Kwd(KwdInterface), Kwd(KwdTypedef):
				return config.atType;
			default:
				return config.atOther;
		}
	}

	static function markDblDot(parsedCode:ParsedCode, config:LineEndConfig) {
		if (config.caseColon == None) {
			return;
		}
		var dblDotTokens:Array<TokenTree> = parsedCode.root.filter([DblDot], ALL);
		for (token in dblDotTokens) {
			if ((token.parent.is(Kwd(KwdCase))) || (token.parent.is(Kwd(KwdDefault)))) {
				parsedCode.tokenList.lineEndAfter(token);
			}
		}
	}

	static function markSharp(parsedCode:ParsedCode, config:LineEndConfig) {
		var sharpTokens:Array<TokenTree> = parsedCode.root.filter([
			Sharp(SHARP_IF), Sharp(SHARP_ELSE), Sharp(SHARP_ELSE_IF), Sharp(SHARP_END), Sharp("error")
		], ALL);
		for (token in sharpTokens) {
			switch (token.tok) {
				case Sharp(SHARP_IF), Sharp(SHARP_ELSE_IF):
					var lastChild:TokenTree = lastToken(token.getFirstChild());
					if (lastChild == null) {
						continue;
					}
					if (config.sharp == None) {
						parsedCode.tokenList.whitespace(lastChild, After);
						continue;
					}
					if (isInlineSharp(token, parsedCode)) {
						parsedCode.tokenList.noLineEndBefore(token);
						continue;
					}
					parsedCode.tokenList.lineEndAfter(lastChild);
				case Sharp(SHARP_ELSE):
					if (isInlineSharp(token, parsedCode)) {
						parsedCode.tokenList.noLineEndBefore(token);
						continue;
					}
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
					}
					parsedCode.tokenList.lineEndAfter(token);
				case Sharp("error"):
					var lastChild:TokenTree = lastToken(token.getFirstChild());
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
						var lastChild:TokenTree = lastToken(child);
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
		var lastChild:TokenTree = lastToken(token);
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

	public static function lastToken(token:TokenTree):TokenTree {
		if (token == null) {
			return null;
		}
		if (token.children == null) {
			return token;
		}
		if (token.children.length <= 0) {
			return token;
		}
		var lastChild:TokenTree = token.getLastChild();
		while (lastChild != null) {
			var newLast:TokenTree = lastChild.getLastChild();
			if (newLast == null) {
				return lastChild;
			}
			lastChild = newLast;
		}
		return null;
	}
}
