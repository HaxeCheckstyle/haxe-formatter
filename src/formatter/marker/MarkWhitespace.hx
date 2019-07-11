package formatter.marker;

import formatter.config.WhitespaceConfig;
import formatter.config.WhitespacePolicy;

class MarkWhitespace extends MarkerBase {
	public function run() {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Binop(OpLt):
					if (TokenTreeCheckUtils.isTypeParameter(token)) {
						whitespace(token, config.whitespace.typeParamOpenPolicy);
					} else {
						whitespace(token, config.whitespace.binopPolicy);
					}
				case Binop(OpGt):
					markGt(token);
				case Binop(OpInterval):
					whitespace(token, config.whitespace.intervalPolicy);
				#if (haxe_ver >= 4.0)
				case Binop(OpIn):
					whitespace(token, Around);
				#end
				case Binop(OpMult):
					if (TokenTreeCheckUtils.isImport(token.parent)) {
						whitespace(token, None);
					} else {
						whitespace(token, config.whitespace.binopPolicy);
					}
				case Binop(OpSub):
					if (TokenTreeCheckUtils.filterOpSub(token)) {
						var policy:WhitespacePolicy = config.whitespace.binopPolicy.remove(After);
						var prev:TokenInfo = getPreviousToken(token);
						switch (prev.token.tok) {
							case POpen, BkOpen:
								policy = policy.remove(Before);
							default:
						}
						whitespace(token, policy);
					} else {
						whitespace(token, config.whitespace.binopPolicy);
					}
				case Binop(_):
					whitespace(token, config.whitespace.binopPolicy);
				case Unop(_):
					markUnop(token);
				case Comma:
					whitespace(token, config.whitespace.commaPolicy);
				case Dollar(_):
					markDollar(token);
				case DblDot:
					markDblDot(token);
				case Kwd(_):
					markKeyword(token);
				case POpen:
					markPOpen(token);
				case PClose:
					markPClose(token);
				case BrOpen:
					markBrOpen(token);
				case BrClose:
					markBrClose(token);
				case BkOpen:
					successiveParenthesis(token, false, config.whitespace.openingBracketPolicy, config.whitespace.compressSuccessiveParenthesis);
				case BkClose:
					successiveParenthesis(token, true, config.whitespace.closingBracketPolicy, config.whitespace.compressSuccessiveParenthesis);
				case Question:
					if (TokenTreeCheckUtils.isTernary(token)) {
						whitespace(token, config.whitespace.ternaryPolicy);
					} else {
						whitespace(token, NoneAfter);
					}
				case Sharp(_):
					markSharp(token);
				case Semicolon:
					markSemicolon(token);
				case Const(CIdent(MarkEmptyLines.FINAL)):
					whitespace(token, After);
				case Const(CIdent("is")):
					var parent:Null<TokenTree> = token.access().parent().is(POpen).token;
					if (parent != null) {
						var prev:Null<TokenInfo> = getPreviousToken(parent);
						if ((prev != null) && (prev.token.is(POpen))) {
							whitespace(token, Around);
						}
					}
					fixConstAfterConst(token);
				case Const(CIdent("from")), Const(CIdent("to")):
					var parent:Null<TokenTree> = token.access().parent().parent().is(Kwd(KwdAbstract)).token;
					if (parent != null) {
						whitespace(token, Around);
						wrapBefore(token, true);
					}
					fixConstAfterConst(token);
				case Const(_):
					fixConstAfterConst(token);
				case Arrow:
					markArrow(token);
				case CommentLine(_):
					whitespace(token, Before);
				case Comment(_):
					markComment(token);
				default:
			}
			return GO_DEEPER;
		});
	}

	function markGt(token:TokenTree) {
		if (TokenTreeCheckUtils.isOpGtTypedefExtension(token)) {
			whitespace(token, config.whitespace.typeExtensionPolicy);
			return;
		}
		if (TokenTreeCheckUtils.isTypeParameter(token)) {
			var policy:WhitespacePolicy = config.whitespace.typeParamClosePolicy;
			var next:Null<TokenInfo> = getNextToken(token);
			if (next != null) {
				switch (next.token.tok) {
					case Kwd(_):
						policy = policy.add(After);
					case Comma, Semicolon:
						policy = policy.remove(After);
					case Binop(OpGt), PClose, BrClose:
						policy = policy.remove(After);
					default:
				}
			}
			whitespace(token, policy);
		} else {
			whitespace(token, config.whitespace.binopPolicy);
		}
	}

	function fixConstAfterConst(token:TokenTree) {
		var next:Null<TokenInfo> = getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Const(_), Kwd(_):
					whitespace(token, After);
				default:
			}
		}
	}

	public function successiveParenthesis(token:TokenTree, closing:Bool, policy:WhitespacePolicy, compress:Bool) {
		var next:Null<TokenInfo> = getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Dot, Comma, DblDot, Semicolon:
					policy = policy.remove(After);
				case Binop(OpGt):
					if (token.is(BrClose)) {
						policy = policy.remove(After);
					}
				case Binop(OpArrow):
					policy = policy.add(After);
				case Kwd(_):
					if (closing) {
						policy = policy.add(After);
					}
				default:
			}
		}
		if (!compress) {
			whitespace(token, policy);
			return;
		}
		if (closing) {
			if (next != null) {
				switch (next.token.tok) {
					case BrClose:
						policy = policy.remove(After);
					case POpen, PClose, BrOpen, BkOpen, BkClose:
						if (token.is(PClose)) {
							switch (TokenTreeCheckUtils.getPOpenType(token.parent)) {
								case CONDITION:
									policy = policy.add(After);
								case PARAMETER:
									policy = policy.add(After);
								case FORLOOP:
									policy = policy.add(After);
								default:
									policy = policy.remove(After);
							}
						} else {
							policy = policy.remove(After);
						}
					default:
				}
			}
		} else {
			var prev:Null<TokenInfo> = getPreviousToken(token);
			if (prev != null) {
				switch (prev.token.tok) {
					case POpen, BrOpen, BkOpen, IntInterval(_), Binop(OpInterval):
						policy = policy.remove(Before);
					case Binop(OpLt):
						if (token.is(BrOpen)) {
							return;
						}
					case DblDot:
						switch (prev.whitespaceAfter) {
							case None:
								policy = policy.remove(Before);
							case Space:
								policy = policy.add(Before);
							case Newline:
						}
					case Arrow:
						return;
					case Comma:
						switch (config.whitespace.commaPolicy) {
							case After, OnlyAfter, Around:
								policy = policy.add(Before);
							default:
						}
					default:
				}
			}
		}
		whitespace(token, policy);
	}

	function markKeyword(token:TokenTree) {
		var prev:Null<TokenInfo> = getPreviousToken(token);
		if (prev != null) {
			switch (prev.token.tok) {
				case PClose:
					prev.whitespaceAfter = Space;
				case Const(_):
					prev.whitespaceAfter = Space;
				case At:
					return;
				default:
			}
		}
		switch (token.tok) {
			case Kwd(KwdNull), Kwd(KwdTrue), Kwd(KwdFalse), Kwd(KwdThis), Kwd(KwdDefault), Kwd(KwdContinue):
				var next:Null<TokenInfo> = getNextToken(token);
				if (next != null) {
					switch (next.token.tok) {
						case Kwd(_):
							whitespace(token, After);
							return;
						case Const(CIdent(_)):
							whitespace(token, After);
							return;
						case Question:
							whitespace(token, After);
							return;
						default:
					}
				}
				whitespace(token, NoneAfter);
			case Kwd(KwdExtends), Kwd(KwdImplements):
				whitespace(token, Around);
			case Kwd(KwdIf), Kwd(KwdElse):
				whitespace(token, config.whitespace.ifPolicy);
			case Kwd(KwdDo):
				whitespace(token, config.whitespace.doPolicy);
			case Kwd(KwdWhile):
				whitespace(token, config.whitespace.whilePolicy);
			case Kwd(KwdFor):
				whitespace(token, config.whitespace.forPolicy);
			case Kwd(KwdSwitch):
				whitespace(token, config.whitespace.switchPolicy);
			case Kwd(KwdTry):
				whitespace(token, config.whitespace.tryPolicy);
			case Kwd(KwdCatch):
				whitespace(token, config.whitespace.catchPolicy);
			#if (haxe_ver < 4.0)
			case Kwd(KwdIn):
				whitespace(token, Around);
			#end
			case Kwd(KwdReturn):
				whitespace(token, After);
			case Kwd(KwdUntyped):
				whitespace(token, After);
			case Kwd(_):
				var next:Null<TokenInfo> = getNextToken(token);
				if (next != null) {
					switch (next.token.tok) {
						case POpen:
							return;
						case Dot:
							return;
						default:
					}
				}
				whitespace(token, After);
			default:
		}
	}

	function markUnop(token:TokenTree) {
		var next:Null<TokenInfo> = getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Comma, Semicolon:
					return;
				case PClose, BkClose, BrClose:
					return;
				default:
			}
		}
		var prev:Null<TokenInfo> = getPreviousToken(token);
		if (prev == null) {
			return;
		}
		switch (prev.token.tok) {
			case Const(CIdent(_)):
				switch (token.tok) {
					case Unop(OpNot), Unop(OpNeg), Unop(OpNegBits):
						return;
					default:
				}
				whitespace(token, After);
			default:
		}
	}

	function markDollar(token:TokenTree) {
		var next:Null<TokenInfo> = getNextToken(token);
		if (next == null) {
			return;
		}
		switch (next.token.tok) {
			case Kwd(_):
				whitespace(token, After);
			case Const(_):
				whitespace(token, After);
			default:
		}
	}

	function markDblDot(token:TokenTree) {
		var type:Null<ColonType> = TokenTreeCheckUtils.getColonType(token);
		if (type == null) {
			type = UNKNOWN;
		}
		var policy:WhitespacePolicy = config.whitespace.colonPolicy;
		switch (type) {
			case SWITCH_CASE:
				policy = config.whitespace.caseColonPolicy;
			case TYPE_HINT:
				policy = config.whitespace.typeHintColonPolicy;
			case TYPE_CHECK:
				policy = config.whitespace.typeCheckColonPolicy;
			case TERNARY:
				policy = config.whitespace.ternaryPolicy;
			case OBJECT_LITERAL:
				policy = config.whitespace.objectFieldColonPolicy;
			case AT:
				whitespace(token, None);
				return;
			case UNKNOWN:
				policy = config.whitespace.colonPolicy;
		}
		var prev:Null<TokenInfo> = getPreviousToken(token);
		if (prev != null) {
			switch (prev.token.tok) {
				case Sharp(_):
					policy = policy.add(Before);
				case PClose, Const(_):
					if ((token.parent != null) && (token.parent.tok != null)) {
						switch (token.parent.tok) {
							case Sharp(MarkLineEnds.SHARP_IF):
								policy = policy.add(Before);
							default:
						}
					}
				default:
			}
		}
		whitespace(token, policy);
	}

	function markSemicolon(token:TokenTree) {
		var next:Null<TokenInfo> = getNextToken(token);
		var policy:WhitespacePolicy = config.whitespace.semicolonPolicy;
		if (next != null) {
			switch (next.token.tok) {
				case BrClose:
					policy = policy.remove(After);
				default:
			}
		}
		whitespace(token, policy);
	}

	function markSharp(token:TokenTree) {
		switch (token.tok) {
			case Sharp(MarkLineEnds.SHARP_IF):
				whitespace(token, After);
				var prev:Null<TokenInfo> = getPreviousToken(token);
				if (prev != null) {
					switch (prev.token.tok) {
						case Const(_), Kwd(_):
							whitespace(token, Before);
						default:
					}
				}
				var next:Null<TokenInfo> = getNextToken(token);
				if (next != null) {
					var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(token.getFirstChild());
					if (lastChild != null) {
						whitespace(lastChild, After);
					}
				}
			case Sharp(MarkLineEnds.SHARP_ELSE_IF):
				whitespace(token, Around);
			case Sharp(MarkLineEnds.SHARP_ELSE):
				whitespace(token, Around);
			case Sharp(MarkLineEnds.SHARP_END):
				var prev:Null<TokenInfo> = getPreviousToken(token);
				if (prev != null) {
					switch (prev.token.tok) {
						case POpen, BrOpen, BkOpen:
						default:
							whitespace(token, Before);
					}
				}
				var next:Null<TokenInfo> = getNextToken(token);
				if (next != null) {
					switch (next.token.tok) {
						case Comma, Semicolon:
						case Const(_), Kwd(_), POpen, BrOpen, BkOpen, Question:
							whitespace(token, After);
						default:
					}
				}
			case Sharp("error"):
				whitespace(token, After);
			default:
		}
	}

	function markArrow(token:TokenTree) {
		var arrowType:Null<ArrowType> = TokenTreeCheckUtils.getArrowType(token);
		if (arrowType == null) {
			arrowType = ARROW_FUNCTION;
		}
		switch (arrowType) {
			case ARROW_FUNCTION:
				whitespace(token, config.whitespace.arrowFunctionsPolicy);
			case FUNCTION_TYPE_HAXE3:
				whitespace(token, config.whitespace.functionTypeHaxe3Policy);
			case FUNCTION_TYPE_HAXE4:
				whitespace(token, config.whitespace.functionTypeHaxe4Policy);
		}
	}

	function determinePOpenPolicy(token:TokenTree):OpenClosePolicy {
		var type:Null<POpenType> = TokenTreeCheckUtils.getPOpenType(token);
		if (type == null) {
			type = EXPRESSION;
		}
		switch (type) {
			case AT:
				config.whitespace.parenConfig.metadataParens.openingPolicy = config.whitespace.parenConfig.metadataParens.openingPolicy.remove(Before);
				return config.whitespace.parenConfig.metadataParens;
			case PARAMETER:
				switch (token.parent.tok) {
					case Kwd(KwdReturn):
						var policy:OpenClosePolicy = {
							openingPolicy: config.whitespace.parenConfig.anonFuncParamParens.openingPolicy,
							closingPolicy: config.whitespace.parenConfig.anonFuncParamParens.closingPolicy,
							removeInnerWhenEmpty: config.whitespace.parenConfig.anonFuncParamParens.removeInnerWhenEmpty
						}
						switch (policy.openingPolicy) {
							case None:
								policy.openingPolicy = Before;
							case Before:
							case NoneBefore:
								policy.openingPolicy = Before;
							case OnlyBefore:
							case After:
								policy.openingPolicy = Around;
							case OnlyAfter:
								policy.openingPolicy = Around;
							case NoneAfter:
								policy.openingPolicy = OnlyBefore;
							case Around:
						}
						return policy;
					case Const(CIdent(_)), Kwd(KwdNew):
						return config.whitespace.parenConfig.funcParamParens;
					default:
						return config.whitespace.parenConfig.anonFuncParamParens;
				}
			case CALL:
				return config.whitespace.parenConfig.callParens;
			case CONDITION:
				return config.whitespace.parenConfig.conditionParens;
			case FORLOOP:
				return config.whitespace.parenConfig.forLoopParens;
			case EXPRESSION:
				return config.whitespace.parenConfig.expressionParens;
		}
		return config.whitespace.parenConfig.expressionParens;
	}

	function markPOpen(token:TokenTree) {
		var openClosePolicy:OpenClosePolicy = determinePOpenPolicy(token);
		var policy:WhitespacePolicy = openClosePolicy.openingPolicy;
		var prev:Null<TokenInfo> = getPreviousToken(token);
		if (prev != null) {
			switch (prev.token.tok) {
				case Unop(_):
					policy = policy.remove(Before);
				case Binop(_), Comment(_):
					if (prev.spacesAfter > 0) {
						policy = policy.add(Before);
					}
				default:
			}
		}
		if (openClosePolicy.removeInnerWhenEmpty) {
			var next:Null<TokenInfo> = getNextToken(token);
			if (next != null) {
				switch (next.token.tok) {
					case PClose:
						policy = policy.remove(After);
					default:
				}
			}
		}
		successiveParenthesis(token, false, policy, config.whitespace.compressSuccessiveParenthesis);
	}

	function markPClose(token:TokenTree) {
		var openClosePolicy:OpenClosePolicy = determinePOpenPolicy(token.parent);
		var policy:WhitespacePolicy = openClosePolicy.closingPolicy;
		if (openClosePolicy.removeInnerWhenEmpty) {
			var prev:Null<TokenInfo> = getPreviousToken(token);
			if (prev != null) {
				switch (prev.token.tok) {
					case POpen:
						policy = policy.remove(Before);
					default:
				}
			}
		}
		successiveParenthesis(token, true, policy, config.whitespace.compressSuccessiveParenthesis);
	}

	function determineBrOpenPolicy(token:TokenTree):OpenClosePolicy {
		var type:Null<BrOpenType> = TokenTreeCheckUtils.getBrOpenType(token);
		if (type == null) {
			type = UNKNOWN;
		}
		switch (type) {
			case BLOCK:
				return config.whitespace.bracesConfig.blockBraces;
			case TYPEDEFDECL:
				return config.whitespace.bracesConfig.typedefBraces;
			case OBJECTDECL:
				return config.whitespace.bracesConfig.objectLiteralBraces;
			case ANONTYPE:
				return config.whitespace.bracesConfig.anonTypeBraces;
			case UNKNOWN:
				return config.whitespace.bracesConfig.unknownBraces;
		}
		return config.whitespace.bracesConfig.unknownBraces;
	}

	function markBrOpen(token:TokenTree) {
		var openClosePolicy:OpenClosePolicy = determineBrOpenPolicy(token);
		var policy:WhitespacePolicy = openClosePolicy.openingPolicy;
		if (openClosePolicy.removeInnerWhenEmpty) {
			var next:Null<TokenInfo> = getNextToken(token);
			if (next != null) {
				switch (next.token.tok) {
					case BrClose:
						policy = policy.remove(After);
					default:
				}
			}
		}
		successiveParenthesis(token, false, policy, config.whitespace.compressSuccessiveParenthesis);
	}

	function markBrClose(token:TokenTree) {
		var openClosePolicy:OpenClosePolicy = determineBrOpenPolicy(token.parent);
		var policy:WhitespacePolicy = openClosePolicy.closingPolicy;
		if (openClosePolicy.removeInnerWhenEmpty) {
			var prev:Null<TokenInfo> = getPreviousToken(token);
			if (prev != null) {
				switch (prev.token.tok) {
					case BrOpen:
						policy = policy.remove(Before);
					default:
				}
			}
		}
		successiveParenthesis(token, true, policy, config.whitespace.compressSuccessiveParenthesis);
	}

	function markComment(token:TokenTree) {
		var policy:WhitespacePolicy = Around;
		var next:Null<TokenInfo> = getNextToken(token);
		if (next == null) {
			whitespace(token, policy);
			return;
		}
		switch (next.token.tok) {
			case Comma:
				policy.remove(After);
			default:
		}

		whitespace(token, policy);
	}
}
