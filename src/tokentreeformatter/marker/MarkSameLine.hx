package tokentreeformatter.marker;

import tokentreeformatter.config.SameLineConfig;

class MarkSameLine {

	public static function markSameLine(parsedCode:ParsedCode, config:SameLineConfig) {
		markAnonObjectsSameLine(parsedCode, config);

		var tokens:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdIf), Kwd(KwdElse), Kwd(KwdFor), Kwd(KwdWhile), Kwd(KwdDo)], ALL);
		for (token in tokens) {
			switch (token.tok) {
				case Kwd(KwdIf):
					var body:TokenTree = TokenTreeAccessHelper.access(token).firstOf(POpen).nextSibling().token;
					if (body.is(BrOpen)) {
						continue;
					}
					applySameLinePolicy(body, parsedCode, config.ifBody);
				case Kwd(KwdElse):
					var body:TokenTree = TokenTreeAccessHelper.access(token).firstChild().token;
					if (body.is(BrOpen)) {
						continue;
					}
					applySameLinePolicy(body, parsedCode, config.elseBody);
				case Kwd(KwdFor):
					var body:TokenTree = TokenTreeAccessHelper.access(token).firstOf(POpen).nextSibling().token;
					if (body.is(BrOpen)) {
						continue;
					}
					applySameLinePolicy(body, parsedCode, config.forBody);
				case Kwd(KwdWhile):
					if ((token.parent != null) && (token.parent.is(Kwd(KwdDo)))) {
						applySameLinePolicy(token, parsedCode, config.doWhileBody);
						continue;
					}
					var body:TokenTree = TokenTreeAccessHelper.access(token).firstOf(POpen).nextSibling().token;
					if (body.is(BrOpen)) {
						continue;
					}
					applySameLinePolicy(body, parsedCode, config.whileBody);
				case Kwd(KwdDo):
					var body:TokenTree = TokenTreeAccessHelper.access(token).firstChild().token;
					if (body.is(BrOpen)) {
						continue;
					}
					applySameLinePolicy(body, parsedCode, config.doWhileBody);
				default:
			}
		}
	}

	static function applySameLinePolicy(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		switch (policy) {
			case SAME:
				parsedCode.tokenList.wrapBefore(token, true);
				return;
			case NEXT:
				parsedCode.tokenList.lineEndBefore(token);
		}
	}

	static function markAnonObjectsSameLine(parsedCode:ParsedCode, config:SameLineConfig) {}
}