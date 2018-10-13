package formatter.marker;

import formatter.config.Config;
import formatter.config.WrapConfig;

class MarkWrapping extends MarkerBase {
	override public function run() {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Dot:
					if (config.wrapping.wrapBeforeDot) {
						wrapBefore(token, true);
					}
				case BrOpen:
					if (config.wrapping.wrapAfterOpeningBrace) {
						markBrWrapping(token);
					}
				case BkOpen:
					if (config.wrapping.wrapAfterOpeningBracket) {
						arrayWrapping(token);
					}
				case POpen:
					if (config.wrapping.wrapAfterOpeningParenthesis) {
						markPWrapping(token);
					}
				case Binop(OpAdd):
					if (config.wrapping.wrapAfterPlus) {
						wrapAfter(token, true);
					}
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
			return GO_DEEPER;
		});

		markMethodChaining();
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
				wrapParensExpression(token);
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

	public function noWrap(open:TokenTree, close:TokenTree) {
		var colon:TokenTree = open.access().is(BrOpen).parent().is(DblDot).token;
		if (colon != null) {
			var type:ColonType = TokenTreeCheckUtils.getColonType(colon);
			switch (type) {
				case SWITCH_CASE:
				case TYPE_HINT:
				case TYPE_CHECK:
				case TERNARY:
				case OBJECT_LITERAL:
					noLineEndBefore(open);
				case AT:
				case UNKNOWN:
			}
		}
		noWrappingBetween(open, close);
		for (child in open.children) {
			switch (child.tok) {
				case PClose, BrClose, BkClose:
					break;
				case Binop(OpGt):
					continue;
				case Semicolon, Comma:
					continue;
				default:
			}
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
			if (lastChild == null) {
				continue;
			} else {
				switch (lastChild.tok) {
					case Comma, Semicolon:
						noLineEndAfter(lastChild);
					default:
				}
			}
		}
		noLineEndBefore(close);
	}

	public function keep(open:TokenTree, close:TokenTree, addIndent:Int) {
		noWrappingBetween(open, close);
		for (child in open.children) {
			var last:Bool = false;
			switch (child.tok) {
				case PClose, BrClose, BkClose:
					last = true;
				case Binop(OpGt):
					continue;
				case Semicolon, Comma:
					continue;
				default:
			}
			if (parsedCode.isOriginalNewlineBefore(child)) {
				lineEndBefore(child);
				additionalIndent(child, addIndent);
			} else {
				noLineEndBefore(child);
				wrapBefore(child, false);
			}
			if (last) {
				break;
			}
		}
	}

	public function wrapChildOneLineEach(open:TokenTree, close:TokenTree, addIndent:Int = 0, keepFirst:Bool = false) {
		if (!keepFirst) {
			lineEndAfter(open);
		}
		for (child in open.children) {
			switch (child.tok) {
				case PClose, BrClose, BkClose:
					if (keepFirst) {
						noLineEndBefore(child);
					}
					return;
				case Binop(OpGt):
					if (keepFirst) {
						noLineEndBefore(child);
					}
					return;
				case Sharp(_):
					wrapChildOneLineEachSharp(child, addIndent, keepFirst);
				case CommentLine(_):
					var prev:TokenInfo = getPreviousToken(child);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(child, prev.token)) {
							noLineEndBefore(child);
						}
					}
					lineEndAfter(child);
					additionalIndent(child, addIndent);
					continue;
				default:
					additionalIndent(child, addIndent);
			}
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
			if (lastChild == null) {
				lineEndAfter(child);
			} else {
				lineEndAfter(lastChild);
			}
		}
	}

	public function wrapChildOneLineEachSharp(sharp:TokenTree, addIndent:Int = 0, keepFirst:Bool = false) {
		var children:Array<TokenTree> = sharp.children;
		var skipFirst:Bool = false;
		lineEndBefore(sharp);
		switch (sharp.tok) {
			case Sharp(MarkLineEnds.SHARP_IF):
				lineEndAfter(TokenTreeCheckUtils.getLastToken(sharp.getFirstChild()));
				skipFirst = true;
			case Sharp(MarkLineEnds.SHARP_ELSE_IF):
				lineEndAfter(TokenTreeCheckUtils.getLastToken(sharp.getFirstChild()));
				skipFirst = true;
			case Sharp(MarkLineEnds.SHARP_ELSE):
				lineEndAfter(sharp);
			case Sharp(MarkLineEnds.SHARP_END):
				lineEndAfter(sharp);
				return;
			default:
		}
		for (child in children) {
			if (skipFirst) {
				skipFirst = false;
				continue;
			}
			switch (child.tok) {
				case PClose, BrClose, BkClose:
					if (keepFirst) {
						whitespace(child, NoneBefore);
					}
					return;
				case Binop(OpGt):
					if (keepFirst) {
						whitespace(child, NoneBefore);
					}
					return;
				case Sharp(_):
					wrapChildOneLineEachSharp(child, addIndent, keepFirst);
				case CommentLine(_):
					var prev:TokenInfo = getPreviousToken(child);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(child, prev.token)) {
							noLineEndBefore(child);
						}
					}
					lineEndAfter(child);
					additionalIndent(child, addIndent);
					continue;
				default:
					additionalIndent(child, addIndent);
			}
		}
	}

	public function wrapFillLine(open:TokenTree, close:TokenTree, maxLineLength:Int, addIndent:Int = 0, useTrailing:Bool = false) {
		noWrappingBetween(open, close);
		var indent:Int = indenter.calcIndent(open);
		var lineLength:Int = calcLineLengthBefore(open) + indenter.calcAbsoluteIndent(indent + addIndent);
		var first:Bool = true;
		for (child in open.children) {
			switch (child.tok) {
				case PClose, BrClose, BkClose:
					whitespace(child, NoneBefore);
					if (useTrailing) {
						var trailing:Int = calcLineLengthAfter(child);
						if (trailing + lineLength > maxLineLength) {
							var prev:TokenTree = child.previousSibling;
							if (prev == null) {
								return;
							}
							lineEndBefore(prev);
							additionalIndent(prev, addIndent);
						}
					}

					return;
				case Binop(OpGt):
					whitespace(child, NoneBefore);
					return;
				case CommentLine(_):
					var prev:TokenInfo = getPreviousToken(child);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(child, prev.token)) {
							noLineEndBefore(child);
						}
					}
					lineEndAfter(child);
					additionalIndent(child, addIndent);
					continue;
				case Kwd(KwdFunction):
					continue;
				case BrOpen:
					continue;
				default:
					additionalIndent(child, addIndent);
			}
			var tokenLength:Int = calcLength(child);
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
			if (lastChild == null) {
				lastChild = child;
			}
			lineLength += tokenLength;
			if (lineLength > maxLineLength) {
				lineEndBefore(child);
				noLineEndAfter(lastChild);
				indent = indenter.calcIndent(child);
				lineLength = tokenLength + indenter.calcAbsoluteIndent(indent);
			} else {
				noLineEndAfter(lastChild);
			}
			if (first) {
				first = false;
				noLineEndBefore(child);
			}
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
		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var atLength:Int = 0;
		var itemCount:Int = 0;
		for (child in token.children) {
			if (child.is(At)) {
				atLength += calcLength(child);
				continue;
			}
			if (child.is(PClose)) {
				break;
			}
			var length:Int = calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token);
		var rule:WrapRule = determineWrapType(rules, itemCount, maxLength, totalLength, lineLength);
		var addIndent:Int = rule.additionalIndent;
		if (emptyBody) {
			addIndent = 0;
		}
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, pClose, addIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, pClose, addIndent, true);
			case Keep:
				keep(token, pClose, addIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, pClose, config.wrapping.maxLineLength, addIndent, true);
			case NoWrap:
				noWrappingBetween(token, pClose);
		}
	}

	function wrapParensExpression(token:TokenTree) {
		var pClose:TokenTree = token.access().firstOf(PClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var atLength:Int = 0;
		var itemCount:Int = 0;
		for (child in token.children) {
			if (child.is(At)) {
				atLength += calcLength(child);
				continue;
			}
			if (child.is(PClose)) {
				break;
			}
			var length:Int = calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token);
		var rule:WrapRule = determineWrapType(config.wrapping.callParameter, itemCount, maxLength, totalLength, lineLength);
		var addIndent:Int = rule.additionalIndent;
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, pClose, addIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, pClose, addIndent, true);
			case Keep:
				keep(token, pClose, addIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, pClose, config.wrapping.maxLineLength, addIndent);
			case NoWrap:
				noWrappingBetween(token, pClose);
		}
	}

	function wrapCallParameter(token:TokenTree) {
		var pClose:TokenTree = token.access().firstOf(PClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var atLength:Int = 0;
		var itemCount:Int = 0;
		for (child in token.children) {
			var length:Int = 0;
			switch (child.tok) {
				case At:
					atLength += calcLength(child);
					continue;
				case PClose:
					break;
				case BkOpen:
					arrayWrapping(child);
					length = calcLengthUntilNewline(child);
				case BrOpen:
					length = calcLengthUntilNewline(child);
				case Kwd(KwdFunction), Kwd(KwdMacro):
					length = calcLengthUntilNewline(child);
				default:
					length = calcLength(child);
			}
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token);
		var rule:WrapRule = determineWrapType(config.wrapping.callParameter, itemCount, maxLength, totalLength, lineLength);
		var addIndent:Int = rule.additionalIndent;
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, pClose, addIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, pClose, addIndent, true);
			case Keep:
				keep(token, pClose, addIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, pClose, config.wrapping.maxLineLength, addIndent);
			case NoWrap:
				noWrappingBetween(token, pClose);
		}
	}

	function hasEmptyFunctionBody(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		var last:TokenTree = token.getLastChild();
		switch (last.tok) {
			case Semicolon:
				return true;
			default:
		}
		var body:TokenTree = token.nextSibling;
		if (body == null) {
			return true;
		}
		if (body.is(DblDot)) {
			body = body.nextSibling;
		}
		while (body != null && body.is(At)) {
			body = body.nextSibling;
		}
		if (body == null) {
			return true;
		}
		switch (body.tok) {
			case Semicolon:
				return true;
			case BrOpen:
				var brClose:TokenTree = body.getFirstChild();
				if (brClose == null) {
					return false;
				}
				return brClose.is(BrClose);
			default:
				return false;
		}
	}

	function determineWrapType(rules:WrapRules, itemCount:Int, maxItemLength:Int, totalItemLength:Int, lineLength:Int):WrapRule {
		for (rule in rules.rules) {
			if (matchesRule(rule, itemCount, maxItemLength, totalItemLength, lineLength)) {
				return rule;
			}
		}
		return {
			conditions: [],
			type: rules.defaultWrap,
			additionalIndent: rules.defaultAdditionalIndent
		};
	}

	function matchesRule(rule:WrapRule, itemCount:Int, maxItemLength:Int, totalItemLength:Int, lineLength:Int):Bool {
		for (cond in rule.conditions) {
			switch (cond.cond) {
				case ItemCountLargerThan:
					if (itemCount < cond.value) {
						return false;
					}
				case ItemCountLessThan:
					if (itemCount > cond.value) {
						return false;
					}
				case AnyItemLengthLargerThan:
					if (maxItemLength < cond.value) {
						return false;
					}
				case AnyItemLengthLessThan:
					if (maxItemLength > cond.value) {
						return false;
					}
				case TotalItemLengthLargerThan:
					if (totalItemLength < cond.value) {
						return false;
					}
				case TotalItemLengthLessThan:
					if (totalItemLength > cond.value) {
						return false;
					}
				case LineLengthLargerThan:
					if (lineLength < cond.value) {
						return false;
					}
				case LineLengthLessThan:
					if (lineLength > cond.value) {
						return false;
					}
			}
		}
		return true;
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

		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var prevChainElement:TokenTree = chainStart;
		for (index in 0...chainedCalls.length) {
			var chainElement:TokenTree = chainedCalls[index];
			var length:Int = calcLengthBetween(prevChainElement, chainElement);
			prevChainElement = chainElement;
			if (length > maxLength) {
				maxLength = length;
			}
			totalLength += length;
		}
		var itemCount:Int = chainedCalls.length;
		var lineLength:Int = calcLineLength(chainStart);
		var rule:WrapRule = determineWrapType(config.wrapping.methodChain, itemCount, maxLength, totalLength, lineLength);
		var addIndent:Null<Int> = rule.additionalIndent;
		if (addIndent == null) {
			addIndent = 0;
		}
		switch (rule.type) {
			case OnePerLine:
				for (index in 0...chainedCalls.length) {
					var element:TokenTree = chainedCalls[index];
					lineEndBefore(element);
					additionalIndent(element, addIndent);
				}
			case OnePerLineAfterFirst:
				noLineEndBefore(chainStart);
				for (index in 1...chainedCalls.length) {
					var element:TokenTree = chainedCalls[index];
					lineEndBefore(element);
					additionalIndent(element, addIndent);
				}
			case NoWrap:
				for (element in chainedCalls) {
					noLineEndBefore(element);
					wrapBefore(element, false);
				}
			case Keep:
				for (index in 0...chainedCalls.length) {
					var element:TokenTree = chainedCalls[index];
					if (parsedCode.isOriginalNewlineBefore(element)) {
						lineEndBefore(element);
						additionalIndent(element, addIndent);
					} else {
						noLineEndBefore(element);
						wrapBefore(element, false);
					}
				}
			case EqualNumber:
			case FillLine:
		}
	}
}
