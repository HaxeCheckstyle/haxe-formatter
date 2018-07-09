package tokentreeformatter.marker;

import tokentreeformatter.config.WhitespaceConfig;

class MarkWhitespace {
	public static function markWhitespace(parsedCode:ParsedCode, config:WhitespaceConfig) {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Binop(OpLt):
					if (TokenTreeCheckUtils.isTypeParameter(token)) {
						parsedCode.tokenList.whitespace(token, config.typeParamOpenPolicy);
					}
					else {
						parsedCode.tokenList.whitespace(token, config.binopPolicy);
					}
				case Binop(OpGt):
					if (TokenTreeCheckUtils.isTypeParameter(token)) {
						parsedCode.tokenList.whitespace(token, config.typeParamClosePolicy);
					}
					else {
						parsedCode.tokenList.whitespace(token, config.binopPolicy);
					}
				case Binop(_):
					parsedCode.tokenList.whitespace(token, config.binopPolicy);
				case Comma:
					parsedCode.tokenList.whitespace(token, config.commaPolicy);
				case Kwd(_):
					markKeyword(token, parsedCode, config);
				case POpen:
					parsedCode.tokenList.whitespace(token, config.pOpenPolicy);
				case PClose:
					parsedCode.tokenList.whitespace(token, config.pClosePolicy);
				case BrOpen:
					parsedCode.tokenList.whitespace(token, config.brOpenPolicy);
				case BrClose:
					parsedCode.tokenList.whitespace(token, config.brClosePolicy);
				case BkOpen:
					parsedCode.tokenList.whitespace(token, config.bkOpenPolicy);
				case BkClose:
					parsedCode.tokenList.whitespace(token, config.bkClosePolicy);
				case Question:
					parsedCode.tokenList.whitespace(token, NONE_AFTER);
				case Sharp(_):
					parsedCode.tokenList.whitespace(token, AFTER);
				case Semicolon:
					parsedCode.tokenList.whitespace(token, config.semicolonPolicy);
				case Const(CIdent("final")):
					parsedCode.tokenList.whitespace(token, AFTER);
				default:
			}
			return GO_DEEPER;
		});
	}

	static function markKeyword(token:TokenTree, parsedCode:ParsedCode, config:WhitespaceConfig) {
		switch (token.tok) {
			case Kwd(KwdNull), Kwd(KwdTrue), Kwd(KwdFalse), Kwd(KwdThis), Kwd(KwdDefault), Kwd(KwdContinue):
				parsedCode.tokenList.whitespace(token, NONE_AFTER);
			case Kwd(KwdIf):
				parsedCode.tokenList.whitespace(token, config.ifPolicy);
			case Kwd(KwdDo):
				parsedCode.tokenList.whitespace(token, config.doPolicy);
			case Kwd(KwdWhile):
				parsedCode.tokenList.whitespace(token, config.whilePolicy);
			case Kwd(KwdFor):
				parsedCode.tokenList.whitespace(token, config.forPolicy);
			case Kwd(KwdFunction):
				parsedCode.tokenList.whitespace(token, config.functionPolicy);
			case Kwd(KwdTry):
				parsedCode.tokenList.whitespace(token, config.tryPolicy);
			case Kwd(KwdCatch):
				parsedCode.tokenList.whitespace(token, config.catchPolicy);
			case Kwd(_):
				parsedCode.tokenList.whitespace(token, AFTER);
			default:
		}
	}
}