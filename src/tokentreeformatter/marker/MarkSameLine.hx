package tokentreeformatter.marker;

import tokentreeformatter.config.SameLineConfig;

class MarkSameLine {

	public static function markSameLine(parsedCode:ParsedCode, config:SameLineConfig) {
		markAnonObjectsSameLine(parsedCode, config);

		var tokens:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdIf), Kwd(KwdElse), Kwd(KwdFor), Kwd(KwdWhile), Kwd(KwdDo), Kwd(KwdTry), Kwd(KwdCatch)], ALL);
		for (token in tokens) {
			switch (token.tok) {
				case Kwd(KwdIf):
					markBodyAfterPOpen(token, parsedCode, config.ifBody);
				case Kwd(KwdElse):
					markBody(token, parsedCode, config.elseBody);
				case Kwd(KwdFor):
					markBodyAfterPOpen(token, parsedCode, config.forBody);
				case Kwd(KwdWhile):
					if ((token.parent != null) && (token.parent.is(Kwd(KwdDo)))) {
						applySameLinePolicy(token, parsedCode, config.doWhileBody);
						continue;
					}
					markBodyAfterPOpen(token, parsedCode, config.whileBody);
				case Kwd(KwdDo):
					markBody(token, parsedCode, config.doWhileBody);
				case Kwd(KwdTry):
					markBody(token, parsedCode, config.tryBody);
				case Kwd(KwdCatch):
					applySameLinePolicy(token, parsedCode, config.tryCatch);
					markBodyAfterPOpen(token, parsedCode, config.catchBody);
				default:
			}
		}
	}

	static function markBodyAfterPOpen(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		var body:TokenTree = TokenTreeAccessHelper.access(token).firstOf(POpen).nextSibling().token;
		if (body == null) {
			return;
		}
		if (body.is(BrOpen)) {
			return;
		}
		applySameLinePolicy(body, parsedCode, policy);
	}

	static function markBody(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		var body:TokenTree = TokenTreeAccessHelper.access(token).firstChild().token;
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

	static function markAnonObjectsSameLine(parsedCode:ParsedCode, config:SameLineConfig) {}
}