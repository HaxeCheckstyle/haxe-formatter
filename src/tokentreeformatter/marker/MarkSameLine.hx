package tokentreeformatter.marker;

import tokentreeformatter.config.SameLineConfig;
import tokentreeformatter.config.WhitespaceConfig;

class MarkSameLine {
	public static function markSameLine(parsedCode:ParsedCode, configSameLine:SameLineConfig, configWhitespace:WhitespaceConfig) {
		markAnonObjectsSameLine(parsedCode, configSameLine, configWhitespace);
		markDollarSameLine(parsedCode, configSameLine, configWhitespace);

		var tokens:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdIf), Kwd(KwdElse), Kwd(KwdFor), Kwd(KwdWhile), Kwd(KwdDo), Kwd(KwdTry), Kwd(KwdCatch)], ALL);
		for (token in tokens) {
			switch (token.tok) {
				case Kwd(KwdIf):
					markIf(token, parsedCode, configSameLine);
				case Kwd(KwdElse):
					markElse(token, parsedCode, configSameLine);
				case Kwd(KwdFor):
					markFor(token, parsedCode, configSameLine);
				case Kwd(KwdWhile):
					if ((token.parent != null) && (token.parent.is(Kwd(KwdDo)))) {
						applySameLinePolicy(token, parsedCode, configSameLine.doWhileBody);
						continue;
					}
					markBodyAfterPOpen(token, parsedCode, configSameLine.whileBody, false);
				case Kwd(KwdDo):
					markBody(token, parsedCode, configSameLine.doWhileBody, false);
				case Kwd(KwdTry):
					markBody(token, parsedCode, configSameLine.tryBody, false);
				case Kwd(KwdCatch):
					markBodyAfterPOpen(token, parsedCode, configSameLine.catchBody, false);
					applySameLinePolicyChained(token, parsedCode, configSameLine.tryBody, configSameLine.tryCatch);
				default:
			}
		}
	}

	static function shouldIfBeSameLine(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		if (!token.is(Kwd(KwdIf))) {
			return false;
		}
		var parent:TokenTree = token.parent;
		switch (parent.tok) {
			case Kwd(KwdReturn):
				return true;
			case Binop(OpAssign):
				return true;
			case POpen:
				var pos:Position = parent.getPos();
				if ((pos.min < token.pos.min) && (pos.max > token.pos.max)) {
					return true;
				}
			case Kwd(KwdElse):
				return shouldElseBeSameLine(parent);
			default:
		}
		return false;
	}

	static function shouldElseBeSameLine(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		if (!token.is(Kwd(KwdElse))) {
			return false;
		}
		return shouldIfBeSameLine(token.parent);
	}

	static function markIf(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		if (shouldIfBeSameLine(token) && configSameLine.expressionIf == Same) {
			markBodyAfterPOpen(token, parsedCode, Same, configSameLine.expressionIfWithBlocks);
			return;
		}

		markBodyAfterPOpen(token, parsedCode, configSameLine.ifBody, false);
		var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if ((prev != null) && (prev.token.is(Kwd(KwdElse)))) {
			applySameLinePolicy(token, parsedCode, configSameLine.elseIf);
		}
	}

	static function markElse(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		if (shouldElseBeSameLine(token) && configSameLine.expressionIf == Same) {
			markBody(token, parsedCode, Same, configSameLine.expressionIfWithBlocks);
			var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
			if (prev == null) {
				return;
			}
			if (prev.token.is(BrClose)) {
				applySameLinePolicyChained(token, parsedCode, configSameLine.ifBody, configSameLine.ifElse);
			}
			return;
		}

		markBody(token, parsedCode, configSameLine.elseBody, false);
		applySameLinePolicyChained(token, parsedCode, configSameLine.ifBody, configSameLine.ifElse);
	}

	static function markFor(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		var parent:TokenTree = token.parent;
		switch (parent.tok) {
			case BkOpen:
				if (configSameLine.comprehensionFor == Same) {
					markBodyAfterPOpen(token, parsedCode, configSameLine.comprehensionFor, false);
					return;
				}
			default:
		}
		markBodyAfterPOpen(token, parsedCode, configSameLine.forBody, false);
	}

	static function markBodyAfterPOpen(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy, includeBrOpen:Bool) {
		var body:TokenTree = token.access().firstOf(POpen).nextSibling().token;
		if (body == null) {
			return;
		}
		if (body.is(BrOpen)) {
			if (includeBrOpen) {
				markBlockBody(body, parsedCode, policy);
			}
			return;
		}
		applySameLinePolicy(body, parsedCode, policy);
	}

	static function markBody(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy, includeBrOpen:Bool) {
		var body:TokenTree = token.access().firstChild().token;
		if (body == null) {
			return;
		}
		if (body.is(BrOpen)) {
			if (includeBrOpen) {
				markBlockBody(body, parsedCode, policy);
			}
			return;
		}
		applySameLinePolicy(body, parsedCode, policy);
	}

	static function markBlockBody(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		if (token == null) {
			return;
		}
		if (!token.is(BrOpen)) {
			return;
		}
		if ((token.children == null) || (token.children.length > 2)) {
			return;
		}
		parsedCode.tokenList.noLineEndAfter(token);
		for (child in token.children) {
			switch (child.tok) {
				case BrClose:
					var next:TokenInfo = parsedCode.tokenList.getNextToken(child);
					switch (next.token.tok) {
						case Kwd(KwdElse):
							parsedCode.tokenList.noLineEndAfter(child);
						case Kwd(KwdCatch):
							parsedCode.tokenList.noLineEndAfter(child);
						case Semicolon:
							parsedCode.tokenList.whitespace(child, NoneAfter);
						case Comma:
							parsedCode.tokenList.whitespace(child, NoneAfter);
						default:
							continue;
					}
				default:
					var lastToken:TokenTree = MarkLineEnds.lastToken(child);
					if (lastToken == null) {
						return;
					}
					parsedCode.tokenList.noLineEndAfter(lastToken);
			}
		}
	}

	static function applySameLinePolicyChained(token:TokenTree, parsedCode:ParsedCode, previousBlockPolicy:SameLinePolicy, policy:SameLinePolicy) {
		if (policy == Same) {
			var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
			if (prev == null) {
				policy = Next;
			}
			if ((!prev.token.is(BrClose)) && (previousBlockPolicy != Same)) {
				policy = Next;
			}
		}
		applySameLinePolicy(token, parsedCode, policy);
	}

	static function applySameLinePolicy(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		switch (policy) {
			case Same:
				parsedCode.tokenList.wrapBefore(token, true);
				parsedCode.tokenList.noLineEndBefore(token);
				var lastToken:TokenTree = MarkLineEnds.lastToken(token);
				if (lastToken == null) {
					return;
				}
				var next:TokenInfo = parsedCode.tokenList.getNextToken(lastToken);
				if (next == null) {
					return;
				}
				switch (next.token.tok) {
					case Kwd(KwdElse):
						parsedCode.tokenList.noLineEndAfter(lastToken);
					default:
				}
				return;
			case Next:
				parsedCode.tokenList.lineEndBefore(token);
		}
	}

	static function markAnonObjectsSameLine(parsedCode:ParsedCode, config:SameLineConfig, configWhitespace:WhitespaceConfig) {
		var tokens:Array<TokenTree> = parsedCode.root.filter([DblDot], ALL);
		for (token in tokens) {
			if (!token.parent.isCIdent()) {
				continue;
			}
			var brOpen:TokenTree = token.parent.parent;
			if (!brOpen.is(BrOpen)) {
				continue;
			}
			var brClose:TokenTree = brOpen.access().firstOf(BrClose).token;
			parsedCode.tokenList.whitespace(brOpen, NoneAfter);
			parsedCode.tokenList.wrapAfter(brOpen, true);
			if (brClose == null) {
				continue;
			}
			parsedCode.tokenList.whitespace(brClose, NoneBefore);
			parsedCode.tokenList.wrapBefore(brClose, true);
			var next:TokenInfo = parsedCode.tokenList.getNextToken(brClose);
			if (next != null) {
				switch (next.token.tok) {
					case BrOpen:
						parsedCode.tokenList.whitespace(brClose, After);
						continue;
					default:
				}
			}

			// MarkWhitespace.successiveParenthesis(brOpen, parsedCode, configWhitespace.objectOpeningBracePolicy, configWhitespace.compressSuccessiveParenthesis);
			MarkWhitespace.successiveParenthesis(brClose, parsedCode, configWhitespace.objectClosingBracePolicy, configWhitespace.compressSuccessiveParenthesis);
		}
	}

	static function markDollarSameLine(parsedCode:ParsedCode, config:SameLineConfig, configWhitespace:WhitespaceConfig) {
		var tokens:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Dollar(_):
					FOUND_SKIP_SUBTREE;
				default:
					GO_DEEPER;
			}
		});
		for (token in tokens) {
			var brOpen:TokenTree = token.access().firstChild().is(BrOpen).token;
			if (brOpen == null) {
				continue;
			}
			var brClose:TokenTree = brOpen.access().firstOf(BrClose).token;
			parsedCode.tokenList.whitespace(brOpen, None);
			parsedCode.tokenList.whitespace(brClose, None);
			parsedCode.tokenList.wrapBefore(brOpen, false);
			parsedCode.tokenList.wrapAfter(brOpen, false);
			parsedCode.tokenList.wrapBefore(brClose, false);
			parsedCode.tokenList.wrapAfter(brClose, false);
		}
	}
}
