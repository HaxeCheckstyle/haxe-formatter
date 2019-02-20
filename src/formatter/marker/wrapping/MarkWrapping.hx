package formatter.marker.wrapping;

import formatter.config.WrapConfig;

class MarkWrapping extends MarkWrappingBase {
	public function run() {
		var wrappableTokens:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Dot:
					return FOUND_GO_DEEPER;
				case BrOpen:
					return FOUND_GO_DEEPER;
				case BkOpen:
					return FOUND_GO_DEEPER;
				case POpen:
					return FOUND_GO_DEEPER;
				case Binop(OpAdd):
					return FOUND_GO_DEEPER;
				case Binop(OpLt):
					return FOUND_GO_DEEPER;
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
		markOpAddChaining();
		markImplementsExtendsChaining();
	}

	function wrapTypeParameter(token:TokenTree) {
		var close:Null<TokenTree> = token.access().firstOf(Binop(OpGt)).token;
		if ((token.children == null) || (token.children.length <= 1)) {
			return;
		}
		if (token.index + 1 == close.index) {
			whitespace(token, NoneAfter);
			whitespace(close, NoneBefore);
			return;
		}
		var next:Null<TokenInfo> = getNextToken(close);
		if (next != null) {
			switch (next.token.tok) {
				case BrOpen:
					var info:Null<TokenInfo> = getTokenInfo(close);
					if (info.whitespaceAfter != Newline) {
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
		var brClose:Null<TokenTree> = token.access().firstOf(BrClose).token;
		if (isNewLineBefore(token)) {
			return;
		}
		if (parsedCode.isOriginalSameLine(token, brClose)) {
			noWrap(token, brClose);
			return;
		}
	}

	function anonTypeWrapping(token:TokenTree) {
		var brClose:Null<TokenTree> = token.access().firstOf(BrClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		if (token.index + 1 == brClose.index) {
			whitespace(token, NoneAfter);
			whitespace(brClose, NoneBefore);
			return;
		}
		var next:Null<TokenInfo> = getNextToken(brClose);
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
				var prev:Null<TokenInfo> = getPreviousToken(token);
				if (prev == null) {
					return;
				}
				switch (prev.whitespaceAfter) {
					case None:
					case Space:
					case Newline:
						prev.whitespaceAfter = Space;
				}
		}
	}

	function objectLiteralWrapping(token:TokenTree) {
		var brClose:Null<TokenTree> = token.access().firstOf(BrClose).token;
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
						case POpen, Binop(_), Comma:
							noLineEndBefore(token);
						default:
					}
				}
		}
	}

	function markPWrapping(token:TokenTree) {
		var pClose:Null<TokenTree> = token.access().firstOf(PClose).token;
		switch (TokenTreeCheckUtils.getPOpenType(token)) {
			case AT:
				wrapMetadataCallParameter(token);
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
		var bkClose:Null<TokenTree> = token.access().firstOf(BkClose).token;
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
		return super.calcLineLength(token);
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

	function wrapMetadataCallParameter(token:TokenTree) {
		var pClose:TokenTree = token.access().firstOf(PClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		var items:Array<WrappableItem> = makeWrappableItems(token);
		var rule:WrapRule = determineWrapType2(config.wrapping.metadataCallParameter, token, items);
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
			items.push(makeWrappableItem(child, endToken));
		}
		var rule:WrapRule = determineWrapType2(config.wrapping.methodChain, chainOpen, items);
		applyRule(rule, chainOpen, null, items, rule.additionalIndent, false);
	}

	function markOpBoolChaining() {
		var chainStarts:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			if (!token.hasChildren()) {
				return SKIP_SUBTREE;
			}
			for (child in token.children) {
				switch (child.tok) {
					case Binop(OpBoolAnd), Binop(OpBoolOr):
						return FOUND_GO_DEEPER;
					default:
				}
			}
			return GO_DEEPER;
		});
		for (chainStart in chainStarts) {
			markSingleOpBoolChain(chainStart);
		}
	}

	function markSingleOpBoolChain(itemStart:TokenTree) {
		var items:Array<WrappableItem> = [];
		var prev:Null<TokenInfo> = getPreviousToken(itemStart);
		var chainStart:TokenTree = itemStart;
		if (prev != null) {
			chainStart = prev.token;
		}
		var chainEnd:Null<TokenTree> = itemStart.getLastChild();
		if (chainEnd != null) {
			chainEnd = TokenTreeCheckUtils.getLastToken(chainEnd);
			switch (chainEnd.tok) {
				case Semicolon, Comma, PClose:
				default:
					var next:Null<TokenInfo> = getNextToken(chainEnd);
					if (next != null) {
						chainEnd = next.token;
					}
			}
		}
		for (child in itemStart.children) {
			switch (child.tok) {
				case Binop(OpBoolAnd), Binop(OpBoolOr):
					items.push(makeWrappableItem(itemStart, child));
					var next:Null<TokenInfo> = getNextToken(child);
					if (next == null) {
						return;
					}
					itemStart = next.token;
				default:
					continue;
			}
		}
		items.push(makeWrappableItem(itemStart, TokenTreeCheckUtils.getLastToken(itemStart)));

		var rule:WrapRule = determineWrapType2(config.wrapping.opBoolChain, chainStart, items);
		applyRule(rule, chainStart, chainEnd, items, rule.additionalIndent, false);
	}

	function markOpAddChaining() {
		var chainStarts:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			if (!token.hasChildren()) {
				return SKIP_SUBTREE;
			}
			for (child in token.children) {
				switch (child.tok) {
					case Binop(OpAdd), Binop(OpSub):
						return FOUND_GO_DEEPER;
					default:
				}
			}
			return GO_DEEPER;
		});
		for (chainStart in chainStarts) {
			markSingleOpAddChain(chainStart);
		}
	}

	function markSingleOpAddChain(itemContainer:TokenTree) {
		var items:Array<WrappableItem> = [];
		var prev:Null<TokenInfo> = getPreviousToken(findOpAddItemStart(itemContainer));
		var chainStart:TokenTree = findOpAddItemStart(itemContainer);
		var chainEnd:Null<TokenTree> = itemContainer.getLastChild();

		if (chainEnd != null) {
			chainEnd = TokenTreeCheckUtils.getLastToken(chainEnd);
			switch (chainEnd.tok) {
				case Semicolon, Comma:
				default:
					var next:Null<TokenInfo> = getNextToken(chainEnd);
					if (next != null) {
						chainEnd = next.token;
					}
			}
		}
		var next:Null<TokenInfo> = getNextToken(chainStart);
		if (next == null) {
			return;
		}
		var itemStart:TokenTree = next.token;
		for (child in itemContainer.children) {
			switch (child.tok) {
				case Binop(OpAdd), Binop(OpSub):
					items.push(makeWrappableItem(itemStart, child));
					var next:Null<TokenInfo> = getNextToken(child);
					if (next == null) {
						continue;
					}
					itemStart = next.token;
				default:
					continue;
			}
		}
		items.push(makeWrappableItem(itemStart, TokenTreeCheckUtils.getLastToken(itemStart)));
		var rule:WrapRule = determineWrapType2(config.wrapping.opAddSubChain, chainStart, items);
		applyRule(rule, chainStart, null, items, rule.additionalIndent, false);
	}

	function findOpAddItemStart(itemStart:TokenTree):TokenTree {
		if ((itemStart == null) || (itemStart.tok == null)) {
			return itemStart;
		}
		var parent:TokenTree = itemStart;
		while ((parent != null) && (parent.tok != null)) {
			switch (parent.tok) {
				case POpen, BrOpen, BkOpen:
					return parent;
				case Binop(OpAssign), Binop(OpAssignOp(_)):
					return itemStart;
				case Kwd(KwdThis), Kwd(KwdUntyped), Kwd(KwdNull):
				case Kwd(_):
					return parent;
				default:
			}
			itemStart = parent;
			parent = parent.parent;
		}
		return itemStart;
	}

	function makeWrappableItem(start:TokenTree, end:TokenTree):WrappableItem {
		var sameLine:Bool = isSameLineBetween(start, end, false);
		var firstLineLength:Int = 0;
		var lastLineLength:Int = 0;
		if (sameLine) {
			firstLineLength = calcLengthBetween(start, end) + calcTokenLength(end);
		} else {
			firstLineLength = calcLengthUntilNewline(start, end);
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

	function markImplementsExtendsChaining() {
		var classesAndInterfaces:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Kwd(KwdInterface), Kwd(KwdClass):
					return FOUND_SKIP_SUBTREE;
				case Kwd(KwdAbstract), Kwd(KwdEnum), Kwd(KwdTypedef):
					return SKIP_SUBTREE;
				default:
					return GO_DEEPER;
			}
		});
		for (type in classesAndInterfaces) {
			var items:Array<WrappableItem> = [];
			var impls:Array<TokenTree> = type.filterCallback(function(token:TokenTree, index:Int):FilterResult {
				switch (token.tok) {
					case Kwd(KwdExtends), Kwd(KwdImplements):
						return FOUND_SKIP_SUBTREE;
					case Kwd(KwdFunction), Kwd(KwdVar):
						return SKIP_SUBTREE;
					default:
						return GO_DEEPER;
				}
			});
			for (impl in impls) {
				var endToken:TokenTree = TokenTreeCheckUtils.getLastToken(impl);
				items.push(makeWrappableItem(impl, endToken));
			}
			if (items.length <= 0) {
				continue;
			}
			var chainOpen:TokenTree = items[0].first;
			var prev:TokenInfo = getPreviousToken(items[0].first);
			if (prev != null) {
				chainOpen = prev.token;
			}
			var chainEnd:TokenTree = items[items.length - 1].last;
			var rule:WrapRule = determineWrapType2(config.wrapping.implementsExtends, chainOpen, items);
			applyRule(rule, chainOpen, chainEnd, items, rule.additionalIndent, false);
		}
	}
}
