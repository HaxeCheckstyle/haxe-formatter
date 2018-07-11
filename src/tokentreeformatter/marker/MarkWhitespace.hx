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
				case Binop(OpInterval):
					parsedCode.tokenList.whitespace(token, config.intervalPolicy);
				case Binop(_):
					parsedCode.tokenList.whitespace(token, config.binopPolicy);
				case Comma:
					parsedCode.tokenList.whitespace(token, config.commaPolicy);
				case DblDot:
					if ((token.parent.is(Kwd(KwdCase))) || (token.parent.is(Kwd(KwdDefault)))) {
						parsedCode.tokenList.whitespace(token, config.caseDblDotPolicy);
					}
					else {
						parsedCode.tokenList.whitespace(token, config.dblDotPolicy);
					}
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
		var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if ((prev != null) && (prev.token.is(PClose))) {
			prev.whitespaceAfter = SPACE;
		}
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
			case Kwd(KwdSwitch):
				parsedCode.tokenList.whitespace(token, config.switchPolicy);
			case Kwd(KwdTry):
				parsedCode.tokenList.whitespace(token, config.tryPolicy);
			case Kwd(KwdCatch):
				parsedCode.tokenList.whitespace(token, config.catchPolicy);
			case Kwd(_):
				var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
				if (next != null) {
					switch (next.token.tok) {
						case POpen:
							return;
						case Dot:
							return;
						default:
					}
				}
				parsedCode.tokenList.whitespace(token, AFTER);
			default:
		}
	}
}