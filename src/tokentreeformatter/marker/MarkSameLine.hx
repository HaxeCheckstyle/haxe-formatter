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
					markBodyAfterPOpen(token, parsedCode, configSameLine.ifBody);
				case Kwd(KwdElse):
					applySameLinePolicy(token, parsedCode, configSameLine.ifElse);
					markBody(token, parsedCode, configSameLine.elseBody);
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
					applySameLinePolicy(token, parsedCode, configSameLine.tryCatch);
					markBodyAfterPOpen(token, parsedCode, configSameLine.catchBody);
				default:
			}
		}
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

	static function applySameLinePolicy(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		switch (policy) {
			case SAME:
				parsedCode.tokenList.wrapBefore(token, true);
				parsedCode.tokenList.noLineEndBefore(token);
				return;
			case NEXT:
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
			parsedCode.tokenList.noLlineEndAfter(brOpen);
			parsedCode.tokenList.wrapAfter(brOpen, true);
			parsedCode.tokenList.noLineEndBefore(brClose);
			parsedCode.tokenList.wrapBefore(brClose, true);

			MarkWhitespace.successiveParenthesis(brOpen, parsedCode, configWhitespace.objectBrOpenPolicy, configWhitespace.compressSuccessiveParenthesis);
			MarkWhitespace.successiveParenthesis(brClose, parsedCode, configWhitespace.objectBrClosePolicy, configWhitespace.compressSuccessiveParenthesis);
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
			parsedCode.tokenList.whitespace(brOpen, NONE);
			parsedCode.tokenList.whitespace(brClose, NONE);
			parsedCode.tokenList.wrapBefore(brOpen, false);
			parsedCode.tokenList.wrapAfter(brOpen, false);
			parsedCode.tokenList.wrapBefore(brClose, false);
			parsedCode.tokenList.wrapAfter(brClose, false);
		}
	}
}