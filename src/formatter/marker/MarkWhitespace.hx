package formatter.marker;

import formatter.config.WhitespaceConfig;
import formatter.config.WhitespacePolicy;

class MarkWhitespace extends MarkerBase {
	override public function run() {
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
							case POpen:
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
					successiveParenthesis(token, true, config.whitespace.closingParenPolicy, config.whitespace.compressSuccessiveParenthesis);
				case BrOpen:
					successiveParenthesis(token, false, config.whitespace.openingBracePolicy, config.whitespace.compressSuccessiveParenthesis);
				case BrClose:
					successiveParenthesis(token, true, config.whitespace.closingBracePolicy, config.whitespace.compressSuccessiveParenthesis);
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
					var parent:TokenTree = token.access().parent().is(POpen).token;
					if (parent != null) {
						var prev:TokenInfo = getPreviousToken(parent);
						if ((prev != null) && (prev.token.is(POpen))) {
							whitespace(token, Around);
						}
					}
					fixConstAfterConst(token);
				case Const(CIdent("from")), Const(CIdent("to")):
					var parent:TokenTree = token.access().parent().parent().is(Kwd(KwdAbstract)).token;
					if (parent != null) {
						whitespace(token, Around);
					}
					fixConstAfterConst(token);
				case Const(CIdent(_)):
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
			var next:TokenInfo = getNextToken(token);
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
		var next:TokenInfo = getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Const(_), Kwd(_):
					whitespace(token, After);
				default:
			}
		}
	}

	public function successiveParenthesis(token:TokenTree, closing:Bool, policy:WhitespacePolicy, compress:Bool) {
		var next:TokenInfo = getNextToken(token);
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
		if (next != null) {
			switch (next.token.tok) {
				case BrClose:
					var selfInfo:TokenInfo = getTokenInfo(token);
					if ((selfInfo.whitespaceAfter == Newline) || (selfInfo.whitespaceAfter == SpaceOrNewline)) {
						return;
					}
					policy = policy.remove(After);
				case POpen, PClose, BrOpen, BkOpen, BkClose:
					if (token.is(PClose)) {
						switch (TokenTreeCheckUtils.getPOpenType(token.parent)) {
							case CONDITION:
								policy = policy.add(After);
							case PARAMETER:
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
		var prev:TokenInfo = getPreviousToken(token);
		if (prev != null) {
			switch (prev.token.tok) {
				case POpen, BrOpen, BkOpen:
					policy = policy.remove(Before);
				case Binop(OpLt):
					if (token.is(BrOpen)) {
						return;
					}
				case DblDot, Arrow:
					return;
				default:
			}
		}
		whitespace(token, policy);
	}

	function markKeyword(token:TokenTree) {
		var prev:TokenInfo = getPreviousToken(token);
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
				var next:TokenInfo = getNextToken(token);
				if (next != null) {
					switch (next.token.tok) {
						case Kwd(_):
							whitespace(token, After);
							return;
						case Const(CIdent(_)):
							whitespace(token, After);
							return;
						default:
					}
				}
				whitespace(token, NoneAfter);
			case Kwd(KwdExtends), Kwd(KwdImplements):
				whitespace(token, Around);
			case Kwd(KwdIf):
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
				var next:TokenInfo = getNextToken(token);
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
		var next:TokenInfo = getNextToken(token);
		if (next != null) {
			switch (next.token.tok) {
				case Comma, Semicolon:
					return;
				case PClose, BkClose, BrClose:
					return;
				default:
			}
		}
		var prev:TokenInfo = getPreviousToken(token);
		if (prev == null) {
			return;
		}
		switch (prev.token.tok) {
			case Const(CIdent(_)):
				whitespace(token, After);
			default:
		}
	}

	function markDollar(token:TokenTree) {
		var next:TokenInfo = getNextToken(token);
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
		var type:ColonType = TokenTreeCheckUtils.getColonType(token);
		switch (type) {
			case SWITCH_CASE:
				whitespace(token, config.whitespace.caseColonPolicy);
			case TYPE_HINT:
				whitespace(token, config.whitespace.typeHintColonPolicy);
			case TYPE_CHECK:
				whitespace(token, config.whitespace.typeCheckColonPolicy);
			case TERNARY:
				whitespace(token, config.whitespace.ternaryPolicy);
			case OBJECT_LITERAL:
				whitespace(token, config.whitespace.objectFieldColonPolicy);
			case AT:
				whitespace(token, None);
			case UNKNOWN:
				whitespace(token, config.whitespace.colonPolicy);
		}
	}

	function markSemicolon(token:TokenTree) {
		var next:TokenInfo = getNextToken(token);
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
				var prev:TokenInfo = getPreviousToken(token);
				if (prev != null) {
					switch (prev.token.tok) {
						case Const(_), Kwd(_):
							whitespace(token, Before);
						default:
					}
				}
			case Sharp(MarkLineEnds.SHARP_ELSE_IF):
				whitespace(token, Around);
			case Sharp(MarkLineEnds.SHARP_ELSE):
				whitespace(token, Around);
			case Sharp(MarkLineEnds.SHARP_END):
				var prev:TokenInfo = getPreviousToken(token);
				if (prev != null) {
					switch (prev.token.tok) {
						case POpen, BrOpen, BkOpen:
						default:
							whitespace(token, Before);
					}
				}
				var next:TokenInfo = getNextToken(token);
				if (next != null) {
					switch (next.token.tok) {
						case Comma, Semicolon:
						case Const(_), Kwd(_), POpen, BrOpen, BkOpen:
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
		var arrowType:ArrowType = TokenTreeCheckUtils.getArrowType(token);
		switch (arrowType) {
			case ARROW_FUNCTION:
				whitespace(token, config.whitespace.arrowFunctionsPolicy);
			case FUNCTION_TYPE_HAXE3:
				whitespace(token, config.whitespace.functionTypeHaxe3Policy);
			case FUNCTION_TYPE_HAXE4:
				whitespace(token, config.whitespace.functionTypeHaxe4Policy);
		}
	}

	function markPOpen(token:TokenTree) {
		var policy:WhitespacePolicy = config.whitespace.openingParenPolicy;
		var type:POpenType = TokenTreeCheckUtils.getPOpenType(token);
		switch (type) {
			case AT:
				policy = policy.remove(Before);
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
							policy = policy.remove(Before);
							break;
						case At:
							policy = policy.remove(Before);
							break;
						default:
							break;
					}
					parent = parent.parent;
				}
		}
		successiveParenthesis(token, false, policy, config.whitespace.compressSuccessiveParenthesis);
	}

	function markComment(token:TokenTree) {
		var policy:WhitespacePolicy = Around;
		var next:TokenInfo = getNextToken(token);
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
