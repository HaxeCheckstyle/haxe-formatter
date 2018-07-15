package tokentreeformatter.marker;

import tokentreeformatter.config.WhitespaceConfig;
import tokentreeformatter.config.WhitespacePolicy;

class MarkWhitespace {
	public static function markWhitespace(parsedCode:ParsedCode, config:WhitespaceConfig) {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Binop(OpLt):
					if (TokenTreeCheckUtils.isTypeParameter(token)) {
						parsedCode.tokenList.whitespace(token, config.typeParamOpenPolicy);
					} else {
						parsedCode.tokenList.whitespace(token, config.binopPolicy);
					}
				case Binop(OpGt):
					if (TokenTreeCheckUtils.isTypeParameter(token)) {
						parsedCode.tokenList.whitespace(token, config.typeParamClosePolicy);
					} else {
						parsedCode.tokenList.whitespace(token, config.binopPolicy);
					}
				case Binop(OpInterval):
					parsedCode.tokenList.whitespace(token, config.intervalPolicy);
				#if (haxe_ver >= 4.0)
				case Binop(OpIn):
					parsedCode.tokenList.whitespace(token, AROUND);
				#end
				case Binop(OpMult):
					if (TokenTreeCheckUtils.isImport(token.parent)) {
						parsedCode.tokenList.whitespace(token, NONE);
					} else {
						parsedCode.tokenList.whitespace(token, config.binopPolicy);
					}
				case Binop(OpSub):
					if (TokenTreeCheckUtils.filterOpSub(token)) {
						var policy:WhitespacePolicy = WhitespacePolicy.remove(config.binopPolicy, AFTER);
						parsedCode.tokenList.whitespace(token, policy);
					} else {
						parsedCode.tokenList.whitespace(token, config.binopPolicy);
					}
				case Binop(_):
					parsedCode.tokenList.whitespace(token, config.binopPolicy);
				case Comma:
					parsedCode.tokenList.whitespace(token, config.commaPolicy);
				case DblDot:
					markDblDot(token, parsedCode, config);
				case Kwd(_):
					markKeyword(token, parsedCode, config);
				case POpen:
					successiveParenthesis(token, parsedCode, config.pOpenPolicy, config.compressSuccessiveParenthesis);
				case PClose:
					successiveParenthesis(token, parsedCode, config.pClosePolicy, config.compressSuccessiveParenthesis);
				case BrOpen:
					successiveParenthesis(token, parsedCode, config.brOpenPolicy, config.compressSuccessiveParenthesis);
				case BrClose:
					successiveParenthesis(token, parsedCode, config.brClosePolicy, config.compressSuccessiveParenthesis);
				case BkOpen:
					successiveParenthesis(token, parsedCode, config.bkOpenPolicy, config.compressSuccessiveParenthesis);
				case BkClose:
					successiveParenthesis(token, parsedCode, config.bkClosePolicy, config.compressSuccessiveParenthesis);
				case Question:
					if (TokenTreeCheckUtils.isTernary(token)) {
						parsedCode.tokenList.whitespace(token, config.ternaryPolicy);
					} else {
						parsedCode.tokenList.whitespace(token, NONE_AFTER);
					}
				case Sharp(_):
					parsedCode.tokenList.whitespace(token, AFTER);
				case Semicolon:
					parsedCode.tokenList.whitespace(token, config.semicolonPolicy);
				case Const(CIdent("final")):
					parsedCode.tokenList.whitespace(token, AFTER);
				case Const(CIdent("from")), Const(CIdent("to")):
					var parent:TokenTree = token.access().parent().parent().is(Kwd(KwdAbstract)).token;
					if (parent != null) {
						parsedCode.tokenList.whitespace(token, AROUND);
					}
				default:
			}
			return GO_DEEPER;
			});
	}

	public static function successiveParenthesis(token:TokenTree, parsedCode:ParsedCode, policy:WhitespacePolicy, compressSuccessiveParenthesis:Bool) {
		var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Dot, DblDot, Semicolon:
					policy = WhitespacePolicy.remove(policy, AFTER);
				case Binop(OpGt):
					if (token.is(BrClose)) {
						policy = WhitespacePolicy.remove(policy, AFTER);
					}
				default:
			}
		}
		if (!compressSuccessiveParenthesis) {
			parsedCode.tokenList.whitespace(token, policy);
			return;
		}
		if (next != null) {
			switch (next.token.tok) {
				case POpen, PClose, BrOpen, BrClose, BkOpen, BkClose:
					policy = WhitespacePolicy.remove(policy, AFTER);
				default:
			}
		}
		var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if (prev != null) {
			switch (prev.token.tok) {
				case POpen, BrOpen, BkOpen:
					policy = WhitespacePolicy.remove(policy, BEFORE);
				case Binop(OpLt):
					if (token.is(BrOpen)) {
						policy = WhitespacePolicy.remove(policy, BEFORE);
					}
				default:
			}
		}
		parsedCode.tokenList.whitespace(token, policy);
	}

	static function markKeyword(token:TokenTree, parsedCode:ParsedCode, config:WhitespaceConfig) {
		var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if (prev != null) {
			switch (prev.token.tok) {
				case PClose:
					prev.whitespaceAfter = SPACE;
				case Const(_):
					prev.whitespaceAfter = SPACE;
				default:
			}
		}
		switch (token.tok) {
			case Kwd(KwdNull), Kwd(KwdTrue), Kwd(KwdFalse), Kwd(KwdThis), Kwd(KwdDefault), Kwd(KwdContinue):
				parsedCode.tokenList.whitespace(token, NONE_AFTER);
			case Kwd(KwdExtends), Kwd(KwdImplements):
				parsedCode.tokenList.whitespace(token, AROUND);
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
			#if (haxe_ver < 4.0)
			case Kwd(KwdIn):
				parsedCode.tokenList.whitespace(token, AROUND);
			#end
			case Kwd(KwdReturn):
				parsedCode.tokenList.whitespace(token, AFTER);
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

	static function markDblDot(token:TokenTree, ?parsedCode:ParsedCode, config:WhitespaceConfig) {
		if (TokenTreeCheckUtils.isTernary(token)) {
			parsedCode.tokenList.whitespace(token, config.ternaryPolicy);
			return;
		}
		var parent:TokenTree = token.parent;
		if (parent == null) {
			parsedCode.tokenList.whitespace(token, config.dblDotPolicy);
			return;
		}
		switch (parent.tok) {
			case Const(CIdent(_)):
				parent = parent.parent;
				if ((parent != null) && (parent.is(BrOpen))) {
					if (TokenTreeCheckUtils.isBrOpenAnonTypeOrTypedef(parent)) {
						parsedCode.tokenList.whitespace(token, config.typeDblDotPolicy);
					} else {
						parsedCode.tokenList.whitespace(token, config.objectDblDotPolicy);
					}
					return;
				}
			case Kwd(KwdCase), Kwd(KwdDefault):
				parsedCode.tokenList.whitespace(token, config.caseDblDotPolicy);
				return;
			default:
		}

		parsedCode.tokenList.whitespace(token, config.dblDotPolicy);
	}
}