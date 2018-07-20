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
					markGt(token, parsedCode, config);
				case Binop(OpInterval):
					parsedCode.tokenList.whitespace(token, config.intervalPolicy);
				#if (haxe_ver >= 4.0)
				case Binop(OpIn):
					parsedCode.tokenList.whitespace(token, Around);
				#end
				case Binop(OpMult):
					if (TokenTreeCheckUtils.isImport(token.parent)) {
						parsedCode.tokenList.whitespace(token, None);
					} else {
						parsedCode.tokenList.whitespace(token, config.binopPolicy);
					}
				case Binop(OpSub):
					if (TokenTreeCheckUtils.filterOpSub(token)) {
						var policy:WhitespacePolicy = WhitespacePolicy.remove(config.binopPolicy, After);
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
					successiveParenthesis(token, parsedCode, config.openingParenPolicy, config.compressSuccessiveParenthesis);
				case PClose:
					successiveParenthesis(token, parsedCode, config.closingParenPolicy, config.compressSuccessiveParenthesis);
				case BrOpen:
					successiveParenthesis(token, parsedCode, config.openingBracePolicy, config.compressSuccessiveParenthesis);
				case BrClose:
					successiveParenthesis(token, parsedCode, config.closingBracePolicy, config.compressSuccessiveParenthesis);
				case BkOpen:
					successiveParenthesis(token, parsedCode, config.openingBracketPolicy, config.compressSuccessiveParenthesis);
				case BkClose:
					successiveParenthesis(token, parsedCode, config.closingBracketPolicy, config.compressSuccessiveParenthesis);
				case Question:
					if (TokenTreeCheckUtils.isTernary(token)) {
						parsedCode.tokenList.whitespace(token, config.ternaryPolicy);
					} else {
						parsedCode.tokenList.whitespace(token, NoneAfter);
					}
				case Sharp(_):
					parsedCode.tokenList.whitespace(token, After);
				case Semicolon:
					parsedCode.tokenList.whitespace(token, config.semicolonPolicy);
				case Const(CIdent("final")):
					parsedCode.tokenList.whitespace(token, After);
				case Const(CIdent("is")):
					var parent:TokenTree = token.access().parent().is(POpen).token;
					if (parent != null) {
						parsedCode.tokenList.whitespace(token, Around);
					}
					fixConstAfterConst(token, parsedCode);
				case Const(CIdent("from")), Const(CIdent("to")):
					var parent:TokenTree = token.access().parent().parent().is(Kwd(KwdAbstract)).token;
					if (parent != null) {
						parsedCode.tokenList.whitespace(token, Around);
					}
					fixConstAfterConst(token, parsedCode);
				case Const(CIdent(_)):
					fixConstAfterConst(token, parsedCode);
				default:
			}
			return GO_DEEPER;
		});
	}

	static function markGt(token:TokenTree, parsedCode:ParsedCode, config:WhitespaceConfig) {
		if (TokenTreeCheckUtils.isOpGtTypedefExtension(token)) {
			parsedCode.tokenList.whitespace(token, config.typeExtensionPolicy);
			return;
		}
		if (TokenTreeCheckUtils.isTypeParameter(token)) {
			parsedCode.tokenList.whitespace(token, config.typeParamClosePolicy);
			var hasAfter:Bool = false;
			switch (config.typeParamClosePolicy) {
				case After, Around, OnlyAfter:
					hasAfter = true;
				default:
			}
			var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
			if (next != null) {
				switch (next.token.tok) {
					case Kwd(_):
						parsedCode.tokenList.whitespace(token, After);
					case Comma, Semicolon:
						if (hasAfter) {
							parsedCode.tokenList.whitespace(token, NoneAfter);
						}
					case Binop(OpGt), PClose, BrClose:
						if (hasAfter) {
							parsedCode.tokenList.whitespace(token, NoneAfter);
						}
					default:
				}
			}
		} else {
			parsedCode.tokenList.whitespace(token, config.binopPolicy);
		}
	}

	static function fixConstAfterConst(token:TokenTree, parsedCode:ParsedCode) {
		var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Const(_), Kwd(_):
					parsedCode.tokenList.whitespace(token, After);
				default:
			}
		}
	}

	public static function successiveParenthesis(token:TokenTree, parsedCode:ParsedCode, policy:WhitespacePolicy, compressSuccessiveParenthesis:Bool) {
		var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Dot, Comma, DblDot, Semicolon:
					policy = WhitespacePolicy.remove(policy, After);
				case Binop(OpGt):
					if (token.is(BrClose)) {
						policy = WhitespacePolicy.remove(policy, After);
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
					policy = WhitespacePolicy.remove(policy, After);
				default:
			}
		}
		var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if (prev != null) {
			switch (prev.token.tok) {
				case POpen, BrOpen, BkOpen:
					policy = WhitespacePolicy.remove(policy, Before);
				case Binop(OpLt):
					if (token.is(BrOpen)) {
						return;
					}
				case DblDot:
					return;
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
					prev.whitespaceAfter = Space;
				case Const(_):
					prev.whitespaceAfter = Space;
				default:
			}
		}
		switch (token.tok) {
			case Kwd(KwdNull), Kwd(KwdTrue), Kwd(KwdFalse), Kwd(KwdThis), Kwd(KwdDefault), Kwd(KwdContinue):
				parsedCode.tokenList.whitespace(token, NoneAfter);
			case Kwd(KwdExtends), Kwd(KwdImplements):
				parsedCode.tokenList.whitespace(token, Around);
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
				parsedCode.tokenList.whitespace(token, Around);
			#end
			case Kwd(KwdReturn):
				parsedCode.tokenList.whitespace(token, After);
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
				parsedCode.tokenList.whitespace(token, After);
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
			parsedCode.tokenList.whitespace(token, config.colonPolicy);
			return;
		}
		switch (parent.tok) {
			case Const(CIdent(_)):
				parent = parent.parent;
				if ((parent != null) && (parent.is(BrOpen))) {
					var brOpenType:BrOpenType = TokenTreeCheckUtils.getBrOpenType(parent);
					switch (brOpenType) {
						case BLOCK:
							parsedCode.tokenList.whitespace(token, config.colonPolicy);
						case TYPEDEFDECL:
							parsedCode.tokenList.whitespace(token, config.typeHintColonPolicy);
						case OBJECTDECL:
							parsedCode.tokenList.whitespace(token, config.objectFieldColonPolicy);
						case ANONTYPE:
							parsedCode.tokenList.whitespace(token, config.typeHintColonPolicy);
						case UNKNOWN:
							parsedCode.tokenList.whitespace(token, config.colonPolicy);
					}
					return;
				}
			case Kwd(KwdCase), Kwd(KwdDefault):
				parsedCode.tokenList.whitespace(token, config.caseColonPolicy);
				return;
			default:
		}

		parsedCode.tokenList.whitespace(token, config.colonPolicy);
	}
}
