package formatter.marker;

import formatter.config.SameLineConfig;
import formatter.config.WhitespaceConfig;

class MarkSameLine {
	public static function markSameLine(parsedCode:ParsedCode, configSameLine:SameLineConfig, configWhitespace:WhitespaceConfig) {
		markAnonObjectsTypedefsSameLine(parsedCode, configSameLine, configWhitespace);
		markDollarSameLine(parsedCode, configSameLine, configWhitespace);

		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Kwd(KwdIf):
					markIf(token, parsedCode, configSameLine);
				case Kwd(KwdElse):
					markElse(token, parsedCode, configSameLine);
				case Kwd(KwdFor):
					markFor(token, parsedCode, configSameLine);
				case Kwd(KwdWhile):
					if ((token.parent != null) && (token.parent.is(Kwd(KwdDo)))) {
						return GO_DEEPER;
					}
					markWhile(token, parsedCode, configSameLine);
				case Kwd(KwdDo):
					markDoWhile(token, parsedCode, configSameLine);
				case Kwd(KwdTry):
					markTry(token, parsedCode, configSameLine);
				case Kwd(KwdCatch):
					markCatch(token, parsedCode, configSameLine);
				case Kwd(KwdCase):
					markCase(token, parsedCode, configSameLine);
				case Kwd(KwdDefault):
					markCase(token, parsedCode, configSameLine);
				case Kwd(KwdFunction):
					markFunction(token, parsedCode, configSameLine);
				default:
			}
			return GO_DEEPER;
		});
	}

	static function isExpression(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		var parent:TokenTree = token.parent;
		if (parent.tok == null) {
			return false;
		}
		switch (parent.tok) {
			case Kwd(KwdReturn):
				return true;
			case Kwd(KwdUntyped):
				return isExpression(parent);
			case Kwd(KwdFor), Kwd(KwdWhile):
				if (parent.parent.is(BkOpen)) {
					return true;
				}
			case Binop(_):
				return true;
			case POpen:
				var pos:Position = parent.getPos();
				if ((pos.min < token.pos.min) && (pos.max > token.pos.max)) {
					return true;
				}
			case Kwd(KwdElse):
				return shouldElseBeSameLine(parent);
			case DblDot:
				switch (parent.parent.tok) {
					case Const(CIdent(_)):
						if (parent.parent.parent.is(Kwd(KwdCase))) {
							return false;
						}
						return true;
					default:
						return isReturnExpression(parent);
				}
			default:
		}
		return false;
	}

	static function isReturnExpression(token:TokenTree):Bool {
		var parent:TokenTree = token;
		while (parent.parent.tok != null) {
			parent = parent.parent;
			switch (parent.tok) {
				case Kwd(KwdReturn):
					return true;
				case Kwd(KwdFunction):
					return false;
				case POpen:
					return true;
				case DblDot:
					return true;
				case BkOpen:
					return false;
				case Binop(OpAssign):
					return true;
				default:
			}
		}
		return false;
	}

	static function shouldIfBeSameLine(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		if (!token.is(Kwd(KwdIf))) {
			return false;
		}
		return isExpression(token);
	}

	static function shouldElseBeSameLine(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		if (!token.is(Kwd(KwdElse))) {
			return false;
		}
		return shouldIfBeSameLine(token.parent);
	}

	static function shouldTryBeSameLine(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		if (!token.is(Kwd(KwdTry))) {
			return false;
		}
		return isExpression(token);
	}

	static function shouldCatchBeSameLine(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		if (!token.is(Kwd(KwdCatch))) {
			return false;
		}
		return shouldTryBeSameLine(token.parent);
	}

	static function markIf(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		if (shouldIfBeSameLine(token) && configSameLine.expressionIf == Same) {
			markBodyAfterPOpen(token, parsedCode, Same, configSameLine.expressionIfWithBlocks);
			return;
		}

		markBodyAfterPOpen(token, parsedCode, configSameLine.ifBody, false);
		var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
		if ((prev != null) && (prev.token.is(Kwd(KwdElse)))) {
			applySameLinePolicy(token, parsedCode, configSameLine.elseIf);
		}
	}

	static function markElse(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		if (shouldElseBeSameLine(token) && configSameLine.expressionIf == Same) {
			markBody(token, parsedCode, Same, configSameLine.expressionIfWithBlocks);
			var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
			if (prev == null) {
				return;
			}
			if (prev.token.is(BrClose)) {
				applySameLinePolicyChained(token, parsedCode, configSameLine.ifBody, configSameLine.ifElse);
			}
			return;
		}

		markBody(token, parsedCode, configSameLine.elseBody, false);
		applySameLinePolicyChained(token, parsedCode, configSameLine.ifBody, configSameLine.ifElse);
	}

	static function markTry(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		if (shouldTryBeSameLine(token) && configSameLine.expressionTry == Same) {
			markBody(token, parsedCode, Same, false);
			return;
		}
		markBody(token, parsedCode, configSameLine.tryBody, false);
	}

	static function markCatch(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		if (shouldCatchBeSameLine(token) && configSameLine.expressionTry == Same) {
			markBodyAfterPOpen(token, parsedCode, Same, false);
			applySameLinePolicy(token, parsedCode, configSameLine.tryCatch);
			return;
		}
		markBodyAfterPOpen(token, parsedCode, configSameLine.catchBody, false);
		applySameLinePolicyChained(token, parsedCode, configSameLine.tryBody, configSameLine.tryCatch);
	}

	static function markCase(token:TokenTree, parsedCode:ParsedCode, config:SameLineConfig) {
		if (token == null) {
			return;
		}
		var dblDot:TokenTree = token.access().firstOf(DblDot).token;
		if (dblDot == null) {
			return;
		}
		if (checkExpressionCase(token, dblDot, parsedCode, config)) {
			parsedCode.tokenList.noLineEndAfter(dblDot);
			return;
		}
		if (config.caseBody != Same) {
			return;
		}
		if ((dblDot.children != null) && (dblDot.children.length == 1)) {
			parsedCode.tokenList.noLineEndAfter(dblDot);
		}
	}

	static function checkExpressionCase(token:TokenTree, dblDot:TokenTree, parsedCode:ParsedCode, config:SameLineConfig):Bool {
		if (config.expressionCase != Same) {
			return false;
		}
		if (!isReturnExpression(token)) {
			return false;
		}
		if (dblDot.children == null) {
			return false;
		}
		if (dblDot.children.length == 2) {
			var second:TokenTree = dblDot.children[1];
			switch (second.tok) {
				case CommentLine(_):
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(second);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(dblDot, prev.token)) {
							return parsedCode.isOriginalSameLine(dblDot, dblDot.children[0]);
						}
						return false;
					}
				default:
					return false;
			}
		}
		if (dblDot.children.length != 1) {
			return false;
		}
		return parsedCode.isOriginalSameLine(dblDot, dblDot.children[0]);
	}

	static function markFor(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		if (token == null) {
			return;
		}
		var parent:TokenTree = token.parent;
		if ((parent == null) || (parent.tok == null)) {
			return;
		}
		switch (parent.tok) {
			case BkOpen:
				if (configSameLine.comprehensionFor == Same) {
					parsedCode.tokenList.whitespace(token, NoneBefore);
					markBodyAfterPOpen(token, parsedCode, configSameLine.comprehensionFor, false);
					var bkClose:TokenTree = parent.getLastChild();
					parsedCode.tokenList.whitespace(bkClose, NoneBefore);
					return;
				}
			default:
		}
		markBodyAfterPOpen(token, parsedCode, configSameLine.forBody, false);
	}

	static function markWhile(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		if (token == null) {
			return;
		}
		var parent:TokenTree = token.parent;
		if ((parent == null) || (parent.tok == null)) {
			return;
		}
		switch (parent.tok) {
			case BkOpen:
				if (configSameLine.comprehensionFor == Same) {
					parsedCode.tokenList.whitespace(token, NoneBefore);
					markBodyAfterPOpen(token, parsedCode, configSameLine.comprehensionFor, false);
					var bkClose:TokenTree = parent.getLastChild();
					parsedCode.tokenList.whitespace(bkClose, NoneBefore);
					return;
				}
			default:
		}
		markBodyAfterPOpen(token, parsedCode, configSameLine.whileBody, false);
	}

	static function markBodyAfterPOpen(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy, includeBrOpen:Bool) {
		var body:TokenTree = token.access().firstOf(POpen).nextSibling().token;
		while (body != null) {
			switch (body.tok) {
				case BrOpen:
					if (includeBrOpen) {
						markBlockBody(body, parsedCode, policy);
					}
					return;
				case CommentLine(_):
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(body);
					if (prev != null) {
						if (!parsedCode.isOriginalSameLine(body, prev.token)) {
							applySameLinePolicy(body, parsedCode, policy);
							return;
						}
					}
					body = body.nextSibling;
				default:
					break;
			}
		}
		if (body == null) {
			return;
		}

		applySameLinePolicy(body, parsedCode, policy);
	}

	static function markBody(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy, includeBrOpen:Bool) {
		var body:TokenTree = token.access().firstChild().token;
		if (body == null) {
			return;
		}
		if (body.is(BrOpen)) {
			if (includeBrOpen) {
				markBlockBody(body, parsedCode, policy);
			}
			return;
		}
		applySameLinePolicy(body, parsedCode, policy);
	}

	static function markBlockBody(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		if (token == null) {
			return;
		}
		if (!token.is(BrOpen)) {
			return;
		}
		if ((token.children == null) || (token.children.length > 2)) {
			return;
		}
		parsedCode.tokenList.noLineEndAfter(token);
		for (child in token.children) {
			switch (child.tok) {
				case BrClose:
					var next:TokenInfo = parsedCode.tokenList.getNextToken(child);
					switch (next.token.tok) {
						case Kwd(KwdElse):
							parsedCode.tokenList.noLineEndAfter(child);
						case Kwd(KwdCatch):
							parsedCode.tokenList.noLineEndAfter(child);
						case Semicolon:
							parsedCode.tokenList.whitespace(child, NoneAfter);
						case Comma:
							parsedCode.tokenList.whitespace(child, NoneAfter);
						default:
							continue;
					}
				default:
					var lastToken:TokenTree = TokenTreeCheckUtils.getLastToken(child);
					if (lastToken == null) {
						return;
					}
					parsedCode.tokenList.noLineEndAfter(lastToken);
			}
		}
	}

	static function applySameLinePolicyChained(token:TokenTree, parsedCode:ParsedCode, previousBlockPolicy:SameLinePolicy, policy:SameLinePolicy) {
		if (policy == Same) {
			var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
			if (prev == null) {
				policy = Next;
			}
			if ((!prev.token.is(BrClose)) && (previousBlockPolicy != Same)) {
				policy = Next;
			}
		}
		applySameLinePolicy(token, parsedCode, policy);
	}

	static function applySameLinePolicy(token:TokenTree, parsedCode:ParsedCode, policy:SameLinePolicy) {
		switch (policy) {
			case Same:
				parsedCode.tokenList.wrapBefore(token, true);
				parsedCode.tokenList.noLineEndBefore(token);
				var lastToken:TokenTree = TokenTreeCheckUtils.getLastToken(token);
				if (lastToken == null) {
					return;
				}
				var next:TokenInfo = parsedCode.tokenList.getNextToken(lastToken);
				if (next == null) {
					return;
				}
				switch (next.token.tok) {
					case Kwd(KwdElse):
						parsedCode.tokenList.noLineEndAfter(lastToken);
					default:
				}
				return;
			case Next:
				parsedCode.tokenList.lineEndBefore(token);
		}
	}

	static function markAnonObjectsTypedefsSameLine(parsedCode:ParsedCode, config:SameLineConfig, configWhitespace:WhitespaceConfig) {
		var tokens:Array<TokenTree> = parsedCode.root.filter([BrOpen], ALL);
		for (token in tokens) {
			var type:BrOpenType = TokenTreeCheckUtils.getBrOpenType(token);
			switch (type) {
				case BLOCK:
					continue;
				case TYPEDEFDECL:
					markTypedefSameLine(token, parsedCode, config, configWhitespace);
				case OBJECTDECL:
				case ANONTYPE:
				case UNKNOWN:
					continue;
			}
		}
	}

	static function markTypedefSameLine(brOpen:TokenTree, parsedCode:ParsedCode, config:SameLineConfig, configWhitespace:WhitespaceConfig) {}

	static function markDollarSameLine(parsedCode:ParsedCode, config:SameLineConfig, configWhitespace:WhitespaceConfig) {
		var tokens:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Dollar(_):
					FOUND_SKIP_SUBTREE;
				default:
					GO_DEEPER;
			}
		});
		for (token in tokens) {
			var brOpen:TokenTree = token.access().firstChild().is(BrOpen).token;
			if (brOpen == null) {
				continue;
			}
			var brClose:TokenTree = brOpen.access().firstOf(BrClose).token;
			parsedCode.tokenList.whitespace(brOpen, None);
			parsedCode.tokenList.noLineEndAfter(brClose);
			var next:TokenInfo = parsedCode.tokenList.getNextToken(brClose);
			if (next != null) {
				switch (next.token.tok) {
					case PClose, BrClose, BkClose:
						parsedCode.tokenList.whitespace(brClose, None);
					case Semicolon, Dot, DblDot:
						parsedCode.tokenList.whitespace(brClose, None);
					default:
						parsedCode.tokenList.whitespace(brClose, OnlyAfter);
				}
			}
			parsedCode.tokenList.wrapBefore(brOpen, false);
			parsedCode.tokenList.wrapAfter(brOpen, false);
			parsedCode.tokenList.wrapBefore(brClose, false);
			parsedCode.tokenList.wrapAfter(brClose, false);
		}
	}

	static function markFunction(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		var body:TokenTree = token.access().firstChild().isCIdent().token;
		if (body == null) {
			body = token.access().firstChild().is(Kwd(KwdNew)).token;
		}
		var policy:SameLinePolicy = configSameLine.functionBody;
		if (body == null) {
			body = token;
			policy = configSameLine.anonFunctionBody;
		}
		if ((body == null) || (body.children == null)) {
			return;
		}
		var index:Int = 0;
		var foundPOpen:Bool = false;
		while (index < body.children.length) {
			var child:TokenTree = body.children[index++];
			switch (child.tok) {
				case DblDot:
				#if (haxe_ver >= 4.0)
				case Kwd(KwdFinal):
				#end
				case Const(CIdent("final")):
				case Kwd(KwdPublic):
				case Kwd(KwdPrivate):
				case Kwd(KwdStatic):
				case Kwd(KwdOverride):
				case Kwd(KwdExtern):
				case Kwd(KwdInline):
				case Kwd(KwdMacro):
				case BrOpen:
					return;
				case Semicolon:
					return;
				case POpen:
					if (foundPOpen) {
						body = child;
						break;
					}
					foundPOpen = true;
				case At:
				case CommentLine(_):
					return;
				case Binop(OpLt):
				default:
					body = child;
					break;
			}
		}
		if (body == null) {
			return;
		}
		applySameLinePolicy(body, parsedCode, policy);
	}

	static function markDoWhile(token:TokenTree, parsedCode:ParsedCode, configSameLine:SameLineConfig) {
		markBody(token, parsedCode, configSameLine.doWhileBody, false);
		var whileTok:TokenTree = token.access().firstOf(Kwd(KwdWhile)).token;
		if (whileTok == null) {
			return;
		}
		applySameLinePolicy(whileTok, parsedCode, configSameLine.doWhile);
	}
}
