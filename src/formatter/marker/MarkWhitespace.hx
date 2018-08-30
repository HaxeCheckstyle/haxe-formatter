package formatter.marker;

import formatter.config.WhitespaceConfig;
import formatter.config.WhitespacePolicy;

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
						var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
						switch (prev.token.tok) {
							case POpen:
								policy = WhitespacePolicy.remove(policy, Before);
							default:
						}
						parsedCode.tokenList.whitespace(token, policy);
					} else {
						parsedCode.tokenList.whitespace(token, config.binopPolicy);
					}
				case Binop(_):
					parsedCode.tokenList.whitespace(token, config.binopPolicy);
				case Unop(_):
					markUnop(token, parsedCode, config);
				case Comma:
					parsedCode.tokenList.whitespace(token, config.commaPolicy);
				case Dollar(_):
					markDollar(token, parsedCode, config);
				case DblDot:
					markDblDot(token, parsedCode, config);
				case Kwd(_):
					markKeyword(token, parsedCode, config);
				case POpen:
					markPOpen(token, parsedCode, config);
				case PClose:
					successiveParenthesis(token, true, parsedCode, config.closingParenPolicy, config.compressSuccessiveParenthesis);
				case BrOpen:
					successiveParenthesis(token, false, parsedCode, config.openingBracePolicy, config.compressSuccessiveParenthesis);
				case BrClose:
					successiveParenthesis(token, true, parsedCode, config.closingBracePolicy, config.compressSuccessiveParenthesis);
				case BkOpen:
					successiveParenthesis(token, false, parsedCode, config.openingBracketPolicy, config.compressSuccessiveParenthesis);
				case BkClose:
					successiveParenthesis(token, true, parsedCode, config.closingBracketPolicy, config.compressSuccessiveParenthesis);
				case Question:
					if (TokenTreeCheckUtils.isTernary(token)) {
						parsedCode.tokenList.whitespace(token, config.ternaryPolicy);
					} else {
						parsedCode.tokenList.whitespace(token, NoneAfter);
					}
				case Sharp(_):
					parsedCode.tokenList.whitespace(token, Around);
				case Semicolon:
					markSemicolon(token, parsedCode, config);
				case Const(CIdent("final")):
					parsedCode.tokenList.whitespace(token, After);
				case Const(CIdent("is")):
					var parent:TokenTree = token.access().parent().is(POpen).token;
					if (parent != null) {
						var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(parent);
						if ((prev != null) && (prev.token.is(POpen))) {
							parsedCode.tokenList.whitespace(token, Around);
						}
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
				case Arrow:
					markArrow(token, parsedCode, config);
				case CommentLine(_):
					parsedCode.tokenList.whitespace(token, Before);
				case Comment(_):
					parsedCode.tokenList.whitespace(token, Around);
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
			var policy:WhitespacePolicy = config.typeParamClosePolicy;
			var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
			if (next != null) {
				switch (next.token.tok) {
					case Kwd(_):
						policy = WhitespacePolicy.add(policy, After);
					case Comma, Semicolon:
						policy = WhitespacePolicy.remove(policy, After);
					case Binop(OpGt), PClose, BrClose:
						policy = WhitespacePolicy.remove(policy, After);
					default:
				}
			}
			parsedCode.tokenList.whitespace(token, policy);
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

	public static function successiveParenthesis(token:TokenTree, closing:Bool, parsedCode:ParsedCode, policy:WhitespacePolicy, compress:Bool) {
		var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Dot, Comma, DblDot, Semicolon:
					policy = WhitespacePolicy.remove(policy, After);
				case Binop(OpGt):
					if (token.is(BrClose)) {
						policy = WhitespacePolicy.remove(policy, After);
					}
				case Binop(OpArrow):
					policy = WhitespacePolicy.add(policy, After);
				case Kwd(_):
					if (closing) {
						policy = WhitespacePolicy.add(policy, After);
					}
				default:
			}
		}
		if (!compress) {
			parsedCode.tokenList.whitespace(token, policy);
			return;
		}
		if (next != null) {
			switch (next.token.tok) {
				case BrClose:
					var selfInfo:TokenInfo = parsedCode.tokenList.getTokenAt(token.index);
					if ((selfInfo.whitespaceAfter == Newline) || (selfInfo.whitespaceAfter == SpaceOrNewline)) {
						return;
					}
					policy = WhitespacePolicy.remove(policy, After);
				case POpen, PClose, BrOpen, BkOpen, BkClose:
					if (token.is(PClose)) {
						switch (TokenTreeCheckUtils.getPOpenType(token.parent)) {
							case CONDITION:
								policy = WhitespacePolicy.add(policy, After);
							case PARAMETER:
								policy = WhitespacePolicy.add(policy, After);
							default:
								policy = WhitespacePolicy.remove(policy, After);
						}
					} else {
						policy = WhitespacePolicy.remove(policy, After);
					}
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
				case DblDot, Arrow:
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
				var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
				if (next != null) {
					switch (next.token.tok) {
						case Kwd(_):
							parsedCode.tokenList.whitespace(token, After);
							return;
						case Const(CIdent(_)):
							parsedCode.tokenList.whitespace(token, After);
							return;
						default:
					}
				}
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
			case Kwd(KwdUntyped):
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

	static function markUnop(token:TokenTree, parsedCode:ParsedCode, config:WhitespaceConfig) {
		var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Comma, Semicolon:
					return;
				case PClose, BkClose, BrClose:
					return;
				default:
			}
		}
		var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if (prev == null) {
			return;
		}
		switch (prev.token.tok) {
			case Const(CIdent(_)):
				parsedCode.tokenList.whitespace(token, After);
			default:
		}
	}

	static function markDollar(token:TokenTree, parsedCode:ParsedCode, config:WhitespaceConfig) {
		var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
		if (next == null) {
			return;
		}
		switch (next.token.tok) {
			case Kwd(_):
				parsedCode.tokenList.whitespace(token, After);
			case Const(_):
				parsedCode.tokenList.whitespace(token, After);
			default:
		}
	}

	static function markDblDot(token:TokenTree, ?parsedCode:ParsedCode, config:WhitespaceConfig) {
		var type:ColonType = TokenTreeCheckUtils.getColonType(token);
		switch (type) {
			case SWITCH_CASE:
				parsedCode.tokenList.whitespace(token, config.caseColonPolicy);
			case TYPE_HINT:
				parsedCode.tokenList.whitespace(token, config.typeHintColonPolicy);
			case TYPE_CHECK:
				parsedCode.tokenList.whitespace(token, config.typeCheckColonPolicy);
			case TERNARY:
				parsedCode.tokenList.whitespace(token, config.ternaryPolicy);
			case OBJECT_LITERAL:
				parsedCode.tokenList.whitespace(token, config.objectFieldColonPolicy);
			case AT:
				parsedCode.tokenList.whitespace(token, None);
			case UNKNOWN:
				parsedCode.tokenList.whitespace(token, config.colonPolicy);
		}
	}

	static function markSemicolon(token:TokenTree, parsedCode:ParsedCode, config:WhitespaceConfig) {
		var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
		var policy:WhitespacePolicy = config.semicolonPolicy;
		if (next != null) {
			switch (next.token.tok) {
				case BrClose:
					policy = WhitespacePolicy.remove(policy, After);
				default:
			}
		}
		parsedCode.tokenList.whitespace(token, policy);
	}

	static function markArrow(token:TokenTree, parsedCode:ParsedCode, config:WhitespaceConfig) {
		var arrowType:ArrowType = TokenTreeCheckUtils.getArrowType(token);
		switch (arrowType) {
			case ARROW_FUNCTION:
				parsedCode.tokenList.whitespace(token, config.arrowFunctionsPolicy);
			case FUNCTION_TYPE_HAXE3:
				parsedCode.tokenList.whitespace(token, config.functionTypeHaxe3Policy);
			case FUNCTION_TYPE_HAXE4:
				parsedCode.tokenList.whitespace(token, config.functionTypeHaxe4Policy);
		}
	}

	static function markPOpen(token:TokenTree, parsedCode:ParsedCode, config:WhitespaceConfig) {
		var policy:WhitespacePolicy = config.openingParenPolicy;
		var type:POpenType = TokenTreeCheckUtils.getPOpenType(token);
		switch (type) {
			case AT:
				policy = WhitespacePolicy.remove(policy, Before);
			case PARAMETER:
			case CALL:
			case FORLOOP:
			case CONDITION, EXPRESSION:
				var parent:TokenTree = token.parent;
				while ((parent != null) && (parent.tok != null)) {
					switch (parent.tok) {
						case Const(CIdent(_)):
						case Dot:
						case DblDot:
						case Unop(_):
							policy = WhitespacePolicy.remove(policy, Before);
							break;
						case At:
							policy = WhitespacePolicy.remove(policy, Before);
							break;
						default:
							break;
					}
					parent = parent.parent;
				}
		}
		successiveParenthesis(token, false, parsedCode, policy, config.compressSuccessiveParenthesis);
	}
}
