package tokentreeformatter.marker;

import tokentreeformatter.config.WrapConfig;

class MarkWrapping {
	public static function markWrapping(parsedCode:ParsedCode, config:WrapConfig) {
		var searchTokens:Array<TokenDef> = [];
		if (config.wrapAfterComma) {
			searchTokens.push(Comma);
		}
		if (config.wrapBeforeDot) {
			searchTokens.push(Dot);
		}
		if (config.wrapAfterOpeningBrace) {
			searchTokens.push(BrOpen);
			searchTokens.push(BrClose);
		}
		if (config.wrapAfterOpeningBracket) {
			searchTokens.push(BkOpen);
			searchTokens.push(BkClose);
		}
		if (searchTokens.length <= 0) {
			return;
		}
		var tokens:Array<TokenTree> = parsedCode.root.filter(searchTokens, ALL);
		for (token in tokens) {
			switch (token.tok) {
				case Comma:
					parsedCode.tokenList.wrapAfter(token, true);
				case Dot:
					parsedCode.tokenList.wrapBefore(token, true);
				case BrOpen:
					parsedCode.tokenList.wrapAfter(token, true);
				case BrClose:
					parsedCode.tokenList.wrapBefore(token, true);
				case BkOpen:
					parsedCode.tokenList.wrapAfter(token, true);
				case BkClose:
					parsedCode.tokenList.wrapBefore(token, true);
				default:
			}
		}
	}
}