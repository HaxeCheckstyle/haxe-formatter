package formatter.marker.wrapping;

import formatter.config.WrapConfig;

class MarkWrapping extends MarkWrappingBase {
	override public function run() {
		var wrappableTokens:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Dot:
					if (config.wrapping.wrapBeforeDot) {
						return FOUND_GO_DEEPER;
					}
				case BrOpen:
					if (config.wrapping.wrapAfterOpeningBrace) {
						return FOUND_GO_DEEPER;
					}
				case BkOpen:
					if (config.wrapping.wrapAfterOpeningBracket) {
						return FOUND_GO_DEEPER;
					}
				case POpen:
					if (config.wrapping.wrapAfterOpeningParenthesis) {
						return FOUND_GO_DEEPER;
					}
				case Binop(OpAdd):
					if (config.wrapping.wrapAfterPlus) {
						return FOUND_GO_DEEPER;
					}
				case Binop(OpLt):
					if (TokenTreeCheckUtils.isTypeParameter(token)) {
						return FOUND_GO_DEEPER;
					}
				case Binop(OpArrow), Arrow:
					return FOUND_GO_DEEPER;
				case CommentLine(_):
					return FOUND_GO_DEEPER;
				default:
			}
			return GO_DEEPER;
		});

		wrappableTokens.reverse();
		for (token in wrappableTokens) {
			switch (token.tok) {
				case Dot:
					wrapBefore(token, true);
				case BrOpen:
					markBrWrapping(token);
				case BkOpen:
					arrayWrapping(token);
				case POpen:
					markPWrapping(token);
				case Binop(OpAdd):
					wrapAfter(token, true);
				case Binop(OpLt):
					if (TokenTreeCheckUtils.isTypeParameter(token)) {
						wrapTypeParameter(token);
					}
				case Binop(OpArrow), Arrow:
					wrapAfter(token, true);
				case CommentLine(_):
					wrapBefore(token, false);
				default:
			}
		}

		markMethodChaining();
		markOpBoolChaining();
	}

	function wrapTypeParameter(token:TokenTree) {
		var close:TokenTree = token.access().firstOf(Binop(OpGt)).token;
		if ((token.children == null) || (token.children.length <= 1)) {
			return;
		}
		if (token.index + 1 == close.index) {
			whitespace(token, NoneAfter);
			whitespace(close, NoneBefore);
			return;
		}
		var next:TokenInfo = getNextToken(close);
		if (next != null) {
			switch (next.token.tok) {
				case BrOpen:
					var info:TokenInfo = getTokenInfo(close);
					if ((info.whitespaceAfter != Newline) && (info.whitespaceAfter != SpaceOrNewline)) {
						whitespace(close, After);
					}
				case POpen:
					wrapAfter(close, true);
				case Semicolon, Dot:
					whitespace(close, NoneAfter);
				case Binop(OpGt):
					whitespace(close, NoneAfter);
				default:
			}
		}
		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var itemCount:Int = 0;
		for (child in token.children) {
			switch (child.tok) {
				case BrClose:
					break;
				case CommentLine(_):
					wrapChildOneLineEach(token, close, 0);
					return;
				default:
			}
			var length:Int = calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token);
		var rule:WrapRule = determineWrapType(config.wrapping.typeParameter, itemCount, maxLength, totalLength, lineLength);
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, close, rule.additionalIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, close, rule.additionalIndent, true);
			case Keep:
				keep(token, close, rule.additionalIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, close, config.wrapping.maxLineLength, rule.additionalIndent, true);
			case NoWrap:
				noWrap(token, close);
		}
	}

	function markBrWrapping(token:TokenTree) {
		switch (TokenTreeCheckUtils.getBrOpenType(token)) {
			case BLOCK:
			case TYPEDEFDECL:
				typedefWrapping(token);
			case OBJECTDECL:
				objectLiteralWrapping(token);
			case ANONTYPE:
				anonTypeWrapping(token);
			case UNKNOWN:
		}
	}

	function typedefWrapping(token:TokenTree) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		if (parsedCode.isOriginalSameLine(token, brClose)) {
			noWrap(token, brClose);
			return;
		}
	}

	function anonTypeWrapping(token:TokenTree) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		if (token.index + 1 == brClose.index) {
			whitespace(token, NoneAfter);
			whitespace(brClose, NoneBefore);
			return;
		}
		var next:TokenInfo = getNextToken(brClose);
		if (next != null) {
			switch (next.token.tok) {
				case BrOpen:
					noLineEndAfter(brClose);
				case Binop(OpGt):
					noLineEndAfter(brClose);
					whitespace(brClose, NoneAfter);
				case Const(CIdent("from")), Const(CIdent("to")):
					noLineEndAfter(brClose);
				case Kwd(_), Const(_):
					lineEndAfter(brClose);
				default:
			}
		}
		if (!parsedCode.isOriginalSameLine(token, brClose)) {
			wrapChildOneLineEach(token, brClose, 0);
			return;
		}
		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var itemCount:Int = 0;
		for (child in token.children) {
			switch (child.tok) {
				case BrClose:
					break;
				case CommentLine(_):
					wrapChildOneLineEach(token, brClose, 0);
					return;
				default:
			}
			var length:Int = calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token);
		var rule:WrapRule = determineWrapType(config.wrapping.anonType, itemCount, maxLength, totalLength, lineLength);
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, brClose, rule.additionalIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, brClose, rule.additionalIndent, true);
			case Keep:
				keep(token, brClose, rule.additionalIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, brClose, config.wrapping.maxLineLength, rule.additionalIndent);
			case NoWrap:
				noWrap(token, brClose);
				var prev:TokenInfo = getPreviousToken(token);
				if (prev == null) {
					return;
				}
				switch (prev.whitespaceAfter) {
					case None:
					case Newline:
						prev.whitespaceAfter = None;
					case Space:
					case SpaceOrNewline:
						prev.whitespaceAfter = Space;
				}
		}
	}

	function objectLiteralWrapping(token:TokenTree) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		if ((token.children == null) || (token.children.length <= 1)) {
			return;
		}
		if (token.index + 1 == brClose.index) {
			whitespace(token, NoneAfter);
			whitespace(brClose, NoneBefore);
			return;
		}
		if (!parsedCode.isOriginalSameLine(token, brClose)) {
			wrapChildOneLineEach(token, brClose, 0);
			return;
		}
		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var itemCount:Int = 0;
		for (child in token.children) {
			switch (child.tok) {
				case BrClose:
					break;
				case CommentLine(_):
					wrapChildOneLineEach(token, brClose, 0);
					return;
				default:
			}
			var length:Int = calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token);
		var rule:WrapRule = determineWrapType(config.wrapping.objectLiteral, itemCount, maxLength, totalLength, lineLength);
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, brClose, rule.additionalIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, brClose, rule.additionalIndent, true);
			case Keep:
				keep(token, brClose, rule.additionalIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, brClose, config.wrapping.maxLineLength, rule.additionalIndent);
			case NoWrap:
				noWrap(token, brClose);
				var next:TokenInfo = getNextToken(brClose);
				if (next != null) {
					switch (next.token.tok) {
						case DblDot:
							noLineEndAfter(brClose);
						case Dot, Comma:
							whitespace(brClose, NoneAfter);
						default:
					}
				}
				var prev:TokenInfo = getPreviousToken(token);
				if (prev != null) {
					switch (prev.token.tok) {
						case Kwd(_):
							noLineEndBefore(token);
							whitespace(token, Before);
						case POpen:
							noLineEndBefore(token);
						default:
					}
				}
		}
	}

	function markPWrapping(token:TokenTree) {
		var pClose:TokenTree = token.access().firstOf(PClose).token;
		switch (TokenTreeCheckUtils.getPOpenType(token)) {
			case AT:
				if (token.children != null) {
					if (isSameLineBetween(token, pClose, true)) {
						noWrappingBetween(token, pClose);
					} else {
						wrapAfter(token, true);
						if (pClose != null) {
							wrapBefore(pClose, false);
						}
						for (child in token.children) {
							if (child.is(PClose)) {
								continue;
							}
							var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
							if (lastChild == null) {
								wrapAfter(lastChild, true);
							} else {
								wrapAfter(lastChild, true);
							}
						}
					}
				}
			case PARAMETER:
				wrapFunctionSignature(token);
			case CALL:
				wrapCallParameter(token);
			case CONDITION:
				wrapAfter(token, true);
				if (pClose != null) {
					wrapBefore(pClose, true);
				}
			case FORLOOP:
			case EXPRESSION:
		}
	}

	function arrayWrapping(token:TokenTree) {
		var bkClose:TokenTree = token.access().firstOf(BkClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var atLength:Int = 0;
		var itemCount:Int = 0;
		for (child in token.children) {
			switch (child.tok) {
				case At:
					atLength += calcLength(child);
					continue;
				case BkClose:
					break;
				case Kwd(KwdFor):
					return;
				case Kwd(KwdWhile):
					return;
				case CommentLine(_):
				default:
					var length:Int = calcLength(child);
					totalLength += length;
					if (length > maxLength) {
						maxLength = length;
					}
					itemCount++;
			}
		}

		var lineLength:Int = calcLineLength(token);
		var rule:WrapRule = determineWrapType(config.wrapping.arrayWrap, itemCount, maxLength, totalLength, lineLength);
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, bkClose, rule.additionalIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, bkClose, rule.additionalIndent, true);
			case Keep:
				keep(token, bkClose, rule.additionalIndent);
			case EqualNumber:
			case FillLine:
				wrapArrayWithMany(token, bkClose, config.wrapping.maxLineLength);
			case NoWrap:
				noWrap(token, bkClose);
		}
		if (atLength > 30) {
			lineEndBefore(token);
		}
	}

	function wrapArrayWithMany(bkOpen:TokenTree, bkClose:TokenTree, maxLineLength:Int) {
		noWrappingBetween(bkOpen, bkClose);
		lineEndAfter(bkOpen);
		var indent:Int = indenter.calcAbsoluteIndent(indenter.calcIndent(bkOpen.children[0]));
		var lineLength:Int = indent;
		for (child in bkOpen.children) {
			if (child.is(At)) {
				continue;
			}
			if (child.is(BkClose)) {
				break;
			}
			var length:Int = calcLength(child);
			if (length + lineLength > maxLineLength) {
				lineEndBefore(child);
				lineLength = length + indent;
			} else {
				var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
				whitespace(lastChild, After);
				lineLength += length;
			}
		}
		lineEndBefore(bkClose);
	}

	override function calcLineLength(token:TokenTree):Int {
		if (token == null) {
			return 0;
		}
		var indent:Int = indenter.calcIndent(token);
		return super.calcLineLength(token) + indenter.calcAbsoluteIndent(indent);
	}

	function wrapFunctionSignature(token:TokenTree) {
		var pClose:TokenTree = token.access().firstOf(PClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		var rules:WrapRules = config.wrapping.functionSignature;
		switch (token.parent.tok) {
			case Kwd(KwdFunction):
				rules = config.wrapping.anonFunctionSignature;
			default:
		}
		var emptyBody:Bool = hasEmptyFunctionBody(token);
		var items:Array<WrappableItem> = makeWrappableItems(token);
		var rule:WrapRule = determineWrapType2(rules, token, items);
		var addIndent:Int = rule.additionalIndent;
		if (emptyBody) {
			addIndent = 0;
		}
		applyRule(rule, token, pClose, items, addIndent, true);
	}

	function wrapCallParameter(token:TokenTree) {
		var pClose:TokenTree = token.access().firstOf(PClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		var items:Array<WrappableItem> = makeWrappableItems(token);
		var rule:WrapRule = determineWrapType2(config.wrapping.callParameter, token, items);
		applyRule(rule, token, pClose, items, rule.additionalIndent, false);
	}

	function markMethodChaining() {
		var chainStarts:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Dot:
					wrapBefore(token, true);
					var prev:TokenInfo = getPreviousToken(token);
					if (prev == null) {
						return GO_DEEPER;
					}
					switch (prev.token.tok) {
						case PClose:
							return FOUND_SKIP_SUBTREE;
						default:
					}

				default:
			}
			return GO_DEEPER;
		});
		for (chainStart in chainStarts) {
			markSingleMethodChain(chainStart);
		}
	}

	function markSingleMethodChain(chainStart:TokenTree) {
		var chainedCalls:Array<TokenTree> = chainStart.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Dot:
					var prev:TokenInfo = getPreviousToken(token);
					if (prev == null) {
						return GO_DEEPER;
					}
					switch (prev.token.tok) {
						case PClose:
							return FOUND_GO_DEEPER;
						default:
					}
				default:
			}
			return GO_DEEPER;
		});

		var firstMethodCall:TokenTree = chainStart.access().parent().isCIdent().parent().is(Dot).token;
		if (firstMethodCall != null) {
			chainedCalls.unshift(firstMethodCall);
			chainStart = firstMethodCall;
		}

		var items:Array<WrappableItem> = [];
		var chainEnd:TokenTree = TokenTreeCheckUtils.getLastToken(chainStart);
		var info:TokenInfo = getPreviousToken(chainStart);
		var chainOpen:TokenTree = chainStart.parent;
		if (info != null) {
			chainOpen = info.token;
		}

		for (index in 0...chainedCalls.length) {
			var child:TokenTree = chainedCalls[index];
			var endToken:TokenTree = chainEnd;
			if (index + 1 < chainedCalls.length) {
				var next:TokenTree = chainedCalls[index + 1];
				info = getPreviousToken(next);
				if (info != null) {
					endToken = info.token;
				}
			}
			var sameLine:Bool = isSameLineBetween(child, endToken, false);
			var firstLineLength:Int = 0;
			var lastLineLength:Int = 0;
			if (sameLine) {
				firstLineLength = calcLengthBetween(child, endToken);
			} else {
				firstLineLength = calcLengthUntilNewline(child);
				lastLineLength = calcLineLengthBefore(endToken) + calcTokenLength(endToken);
			}
			var item:WrappableItem = {
				first: child,
				last: endToken,
				multiline: !sameLine,
				firstLineLength: firstLineLength,
				lastLineLength: lastLineLength
			}
			items.push(item);
		}
		var rule:WrapRule = determineWrapType2(config.wrapping.methodChain, chainOpen, items);
		applyRule(rule, chainOpen, null, items, rule.additionalIndent, false);
	}

	function markOpBoolChaining() {
		var chainEnds:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Binop(OpBoolAnd), Binop(OpBoolOr):
					switch (token.parent.tok) {
						case Binop(OpBoolAnd), Binop(OpBoolOr):
						default:
							return GO_DEEPER;
					}
					var last:TokenTree = token.getLastChild();
					if (last == null) {
						return GO_DEEPER;
					}
					switch (last.tok) {
						case Binop(OpBoolAnd), Binop(OpBoolOr):
							return GO_DEEPER;
						default:
							return FOUND_GO_DEEPER;
					}
				default:
			}
			return GO_DEEPER;
		});
		for (lastOpBool in chainEnds) {
			markSingleOpBoolChain(lastOpBool);
		}
	}

	function markSingleOpBoolChain(lastOpBool:TokenTree) {
		var next:TokenInfo = getNextToken(lastOpBool);
		if (next == null) {
			return;
		}
		var itemStart:TokenTree = next.token;
		var itemEnd:TokenTree = TokenTreeCheckUtils.getLastToken(lastOpBool);
		var chainEnd:TokenTree = itemEnd;
		switch (itemEnd.tok) {
			case Semicolon, Comma:
			default:
				next = getNextToken(itemEnd);
				if (next != null) {
					chainEnd = next.token;
				}
		}
		var items:Array<WrappableItem> = [];
		items.unshift(makeOpBoolItem(itemStart, itemEnd));
		itemStart = lastOpBool;
		var parent:TokenTree = lastOpBool;
		var chainOpen:TokenTree = null;
		var done:Bool = false;
		while (!done) {
			parent = parent.parent;
			switch (parent.tok) {
				case Binop(OpBoolAnd), Binop(OpBoolOr):
					next = getNextToken(parent);
					if (next == null) {
						continue;
					}
					itemEnd = itemStart;
					itemStart = next.token;
					items.unshift(makeOpBoolItem(itemStart, itemEnd));
					itemStart = parent;
				default:
					done = true;
					chainOpen = parent.parent;
					itemEnd = itemStart;
					itemStart = parent;
					items.unshift(makeOpBoolItem(itemStart, itemEnd));
			}
		}
		var rule:WrapRule = determineWrapType2(config.wrapping.opBoolChain, chainOpen, items);
		applyRule(rule, chainOpen, chainEnd, items, rule.additionalIndent, false);
	}

	function makeOpBoolItem(start:TokenTree, end:TokenTree):WrappableItem {
		var sameLine:Bool = isSameLineBetween(start, end, false);
		var firstLineLength:Int = 0;
		var lastLineLength:Int = 0;
		if (sameLine) {
			firstLineLength = calcLengthBetween(start, end) + calcTokenLength(end);
		} else {
			firstLineLength = calcLengthUntilNewline(start);
			lastLineLength = calcLineLengthBefore(end) + calcTokenLength(end);
		}
		return {
			first: start,
			last: end,
			multiline: !sameLine,
			firstLineLength: firstLineLength,
			lastLineLength: lastLineLength
		}
	}
}
