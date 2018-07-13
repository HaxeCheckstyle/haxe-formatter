package tokentreeformatter.marker;

import tokentreeformatter.config.LineEndConfig;

class MarkLineEnds {
	public static function markLineEnds(parsedCode:ParsedCode, config:LineEndConfig) {
		var semicolonTokens:Array<TokenTree> = parsedCode.root.filter([Semicolon], ALL);
		for (token in semicolonTokens) {
			parsedCode.tokenList.lineEndAfter(token);
		}

		markComments(parsedCode, config);
		markBrOpenClose(parsedCode, config);
		markAt(parsedCode, config);
		markDblDot(parsedCode, config);
		markSharp(parsedCode, config);
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
			parsedCode.tokenList.lineEndAfter(token);
		}
	}

	static function markBrOpenClose(parsedCode:ParsedCode, config:LineEndConfig) {
		var brTokens:Array<TokenTree> = parsedCode.root.filter([BrOpen, BrClose], ALL);
		for (token in brTokens) {
			switch (token.tok) {
				case BrOpen:
					if ((token.children != null) && (token.children.length == 1) && (config.emptyCurly == NO_BREAK)) {
						continue;
					}
					switch (config.leftCurly) {
						case NONE:
						case BEFORE:
							beforeLeftCurly(token, parsedCode);
						case AFTER:
							parsedCode.tokenList.lineEndAfter(token);
						case BOTH:
							beforeLeftCurly(token, parsedCode);
							parsedCode.tokenList.lineEndAfter(token);
					}
				case BrClose:
					var parent:TokenTree = token.parent;
					var preventBefore:Bool = false;
					if ((parent.children != null) && (parent.children.length == 1) && (config.emptyCurly == NO_BREAK)) {
						preventBefore = true;
					}
					switch (config.rightCurly) {
						case NONE:
						case BEFORE:
							if (!preventBefore) {
								beforeRightCurly(token, parsedCode);
							}
						case AFTER:
							afterRightCurly(token, parsedCode);
						case BOTH:
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
				prevToken.whitespaceAfter = NL;
		}
	}

	static function beforeRightCurly(token:TokenTree, parsedCode:ParsedCode) {
		var prevToken:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if (prevToken == null) {
			return;
		}
		prevToken.whitespaceAfter = NL;
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
			if (atPolicy == NONE) {
				parsedCode.tokenList.whitespace(lastChild, AFTER);
				continue;
			}

			if (atPolicy == AFTER_LAST) {
				var sibling:TokenTree = token.nextSibling;
				if ((sibling != null) && (sibling.is(At))) {
					parsedCode.tokenList.whitespace(lastChild, AFTER);
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
		if (parent == null) {
			return config.atOther;
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
		if (config.caseDblDot == NONE) {
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
		var sharpTokens:Array<TokenTree> = parsedCode.root.filter([Sharp("if"), Sharp("else"), Sharp("elseif"), Sharp("end")], ALL);
		for (token in sharpTokens) {
			switch (token.tok) {
				case Sharp("if"), Sharp("elseif"):
					var lastChild:TokenTree = lastToken(token.getFirstChild());
					if (lastChild == null) {
						continue;
					}
					if (config.sharp == NONE) {
						parsedCode.tokenList.whitespace(lastChild, AFTER);
						continue;
					}

					parsedCode.tokenList.lineEndAfter(lastChild);
				default:
					parsedCode.tokenList.lineEndAfter(token);
			}
		}
	}

	static function lastToken(token:TokenTree):TokenTree {
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