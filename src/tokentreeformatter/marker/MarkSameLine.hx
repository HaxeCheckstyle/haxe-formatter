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
					markBodyAfterPOpen(token, parsedCode, configSameLine.forBody);
				case Kwd(KwdWhile):
					if ((token.parent != null) && (token.parent.is(Kwd(KwdDo)))) {
						applySameLinePolicy(token, parsedCode, configSameLine.doWhileBody);
						continue;
					}
					markBodyAfterPOpen(token, parsedCode, configSameLine.whileBody);
				case Kwd(KwdDo):
					markBody(token, parsedCode, configSameLine.doWhileBody);
				case Kwd(KwdTry):
					markBody(token, parsedCode, configSameLine.tryBody);
				case Kwd(KwdCatch):
					markBodyAfterPOpen(token, parsedCode, configSameLine.catchBody);
					applySameLinePolicyChained(token, parsedCode, configSameLine.tryBody, configSameLine.tryCatch);
				default:
			}
		}
	}

	static function markIf(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		var parent:TokenTree = token.parent;
		var isExpr:Bool = false;
		switch (parent.tok) {
			case Kwd(KwdReturn):
				isExpr = true;
			case Binop(OpAssign):
				isExpr = true;
			default:
		}
		if (isExpr && configSameLine.expressionIf == Same) {
			markBodyAfterPOpen(token, parsedCode, Same);
			return;
		}

		markBodyAfterPOpen(token, parsedCode, configSameLine.ifBody);
		var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if ((prev != null) && (prev.token.is(Kwd(KwdElse)))) {
			applySameLinePolicy(token, parsedCode, configSameLine.elseIf);
		}
	}

	static function markElse(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		var parent:TokenTree = token.parent.parent;
		var isExpr:Bool = false;
		switch (parent.tok) {
			case Kwd(KwdReturn):
				isExpr = true;
			case Binop(OpAssign):
				isExpr = true;
			default:
		}
		if (isExpr && configSameLine.expressionIf == Same) {
			markBody(token, parsedCode, Same);
			return;
		}

		markBody(token, parsedCode, configSameLine.elseBody);
		applySameLinePolicyChained(token, parsedCode, configSameLine.ifBody, configSameLine.ifElse);
	}

	static function markBodyAfterPOpen(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		var body:TokenTree = token.access().firstOf(POpen).nextSibling().token;
		if (body == null) {
			return;
		}
		if (body.is(BrOpen)) {
			return;
		}
		applySameLinePolicy(body, parsedCode, policy);
	}

	static function markBody(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		var body:TokenTree = token.access().firstChild().token;
		if (body == null) {
			return;
		}
		if (body.is(BrOpen)) {
			return;
		}
		applySameLinePolicy(body, parsedCode, policy);
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
			parsedCode.tokenList.whitespace(brClose, NoneBefore);
			parsedCode.tokenList.wrapBefore(brClose, true);

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
