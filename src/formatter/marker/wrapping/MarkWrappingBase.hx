package formatter.marker.wrapping;

import formatter.config.WrapConfig;

class MarkWrappingBase extends MarkerBase {
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

	public function keep2(open:TokenTree, close:TokenTree, items:Array<WrappableItem>, addIndent:Int) {
		noWrappingBetween(open, close);
		var tokens:Array<TokenTree> = [for (item in items) item.first];
		tokens.push(close);
		for (token in tokens) {
			if (parsedCode.isOriginalNewlineBefore(token)) {
				lineEndBefore(token);
				additionalIndent(token, addIndent);
			} else {
				noLineEndBefore(token);
				wrapBefore(token, false);
			}
		}
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

	public function wrapChildOneLineEach2(open:TokenTree, close:TokenTree, items:Array<WrappableItem>, addIndent:Int = 0, keepFirst:Bool = false) {
		if (items.length <= 0) {
			return;
		}
		for (item in items) {
			additionalIndent(item.first, addIndent);
			lineEndBefore(item.first);
		}
		if (keepFirst) {
			noLineEndAfter(open);
			var lastToken:TokenTree = items[items.length - 1].last;
			switch (lastToken.tok) {
				case Semicolon:
				default:
					noLineEndAfter(items[items.length - 1].last);
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

	public function wrapFillLine2(open:TokenTree, close:TokenTree, items:Array<WrappableItem>, maxLineLength:Int, addIndent:Int = 0,
			useTrailing:Bool = false) {
		noWrappingBetween(open, close);
		if (items.length <= 0) {
			return;
		}
		var indent:Int = indenter.calcIndent(open);
		var lineLength:Int = calcLineLengthBefore(open) + indenter.calcAbsoluteIndent(indent);
		var first:Bool = true;
		for (item in items) {
			var tokenLength:Int = item.firstLineLength;
			if (!first && (lineLength + tokenLength >= maxLineLength)) {
				lineEndBefore(item.first);
				additionalIndent(item.first, addIndent);
				lineLength = indenter.calcAbsoluteIndent(indent + 1 + addIndent);
				if (item.multiline) {
					lineLength += item.lastLineLength;
				} else {
					lineLength += item.firstLineLength;
				}
				continue;
			} else {
				noLineEndBefore(item.first);
				lineLength += tokenLength;
				first = false;
				if (item.multiline) {
					lineLength = indenter.calcAbsoluteIndent(indent + 1 + addIndent) + item.lastLineLength;
				}
			}
		}
		if (useTrailing) {
			var lastItem:WrappableItem = items[items.length - 1];
			var lengthAfter:Int = calcLineLengthAfter(lastItem.last);
			if (lineLength + lengthAfter >= maxLineLength) {
				lineEndBefore(lastItem.first);
				additionalIndent(lastItem.first, addIndent);
			}
		}
		noLineEndAfter(open);
		wrapAfter(open, false);
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

	override function calcLineLength(token:TokenTree):Int {
		var indent:Int = indenter.calcIndent(token);
		return super.calcLineLength(token) + indenter.calcAbsoluteIndent(indent);
	}

	function hasEmptyFunctionBody(token:TokenTree):Bool {
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

	function makeWrappableItems(token:TokenTree):Array<WrappableItem> {
		var items:Array<WrappableItem> = [];
		for (child in token.children) {
			switch (child.tok) {
				case PClose, BkClose, BrClose:
					return items;
				default:
			}
			var endToken:TokenTree = TokenTreeCheckUtils.getLastToken(child);
			var sameLine:Bool = isSameLineBetween(child, endToken, false);
			var firstLineLength:Int = calcLengthUntilNewline(child);
			var lastLineLength:Int = 0;
			if (!sameLine) {
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
		return items;
	}

	function determineWrapType2(rules:WrapRules, token:TokenTree, items:Array<WrappableItem>):WrapRule {
		if (items.length <= 0) {
			return {
				conditions: [],
				type: rules.defaultWrap,
				additionalIndent: rules.defaultAdditionalIndent
			};
		}
		var itemCount:Int = items.length;
		var maxItemLength:Int = 0;
		var totalItemLength:Int = 0;
		var lineLength:Int = calcLineLength(token);
		for (item in items) {
			totalItemLength += item.firstLineLength + item.lastLineLength;
			var length:Int = Math.floor(Math.max(item.firstLineLength, item.lastLineLength));
			if (length > maxItemLength) {
				maxItemLength = length;
			}
		}

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

	function applyRule(rule:WrapRule, open:TokenTree, close:TokenTree, items:Array<WrappableItem>, addIndent:Int, useTrailing:Bool) {
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach2(open, close, items, addIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach2(open, close, items, addIndent, true);
			case Keep:
				keep2(open, close, items, addIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine2(open, close, items, config.wrapping.maxLineLength, addIndent, useTrailing);
			case NoWrap:
				noWrappingBetween(open, close);
		}
	}
}
