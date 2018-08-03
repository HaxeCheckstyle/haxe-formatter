package formatter.marker;

import formatter.config.Config;
import formatter.config.WrapConfig;

class MarkWrapping {
	public static function markWrapping(parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Dot:
					if (config.wrapping.wrapBeforeDot) {
						parsedCode.tokenList.wrapBefore(token, true);
					}
				case BrOpen:
					if (config.wrapping.wrapAfterOpeningBrace) {
						markBrWrapping(token, parsedCode, indenter, config);
					}
				case BkOpen:
					if (config.wrapping.wrapAfterOpeningBracket) {
						arrayWrapping(token, parsedCode, indenter, config);
					}
				case POpen:
					if (config.wrapping.wrapAfterOpeningParenthesis) {
						markPWrapping(token, parsedCode, indenter, config);
					}
				case Binop(OpAdd):
					if (config.wrapping.wrapAfterPlus) {
						parsedCode.tokenList.wrapAfter(token, true);
					}
				case Binop(OpLt):
					if (TokenTreeCheckUtils.isTypeParameter(token)) {
						wrapTypeParameter(token, parsedCode, indenter, config);
					}
				default:
			}
			return GO_DEEPER;
		});
	}

	static function wrapTypeParameter(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		var close:TokenTree = token.access().firstOf(Binop(OpGt)).token;
		if ((token.children == null) || (token.children.length <= 1)) {
			return;
		}
		if (token.index + 1 == close.index) {
			parsedCode.tokenList.whitespace(token, NoneAfter);
			parsedCode.tokenList.whitespace(close, NoneBefore);
			return;
		}
		var next:TokenInfo = parsedCode.tokenList.getNextToken(close);
		if (next != null) {
			switch (next.token.tok) {
				case BrOpen:
					parsedCode.tokenList.whitespace(close, After);
				case Semicolon, Dot, POpen:
					parsedCode.tokenList.whitespace(close, NoneAfter);
				case Binop(OpGt):
					parsedCode.tokenList.whitespace(close, NoneAfter);
				default:
			}
		}
		// if (!parsedCode.isOriginalSameLine(token, close)) {
		// 	wrapChildOneLineEach(token, close, parsedCode, indenter);
		// 	return;
		// }
		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var itemCount:Int = 0;
		for (child in token.children) {
			switch (child.tok) {
				case BrClose:
					break;
				case CommentLine(_):
					wrapChildOneLineEach(token, close, parsedCode, indenter);
					return;
				default:
			}
			var length:Int = parsedCode.tokenList.calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token, parsedCode, indenter);
		var type:WrappingType = determineWrapType(config.wrapping.typeParameter, itemCount, maxLength, totalLength, lineLength);
		switch (type) {
			case OnePerLine:
				wrapChildOneLineEach(token, close, parsedCode, indenter);
			case OnePerLineKeep:
				wrapChildOneLineEach(token, close, parsedCode, indenter, true);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, close, parsedCode, indenter, config.wrapping.maxLineLength);
			case NoWrap:
				noWrap(token, close, parsedCode, indenter);
		}
	}

	static function markBrWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		switch (TokenTreeCheckUtils.getBrOpenType(token)) {
			case BLOCK:
			case TYPEDEFDECL:
			case OBJECTDECL:
				objectLiteralWrapping(token, parsedCode, indenter, config);
			case ANONTYPE:
				anonTypeWrapping(token, parsedCode, indenter, config);
			case UNKNOWN:
		}
	}

	static function anonTypeWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		if (token.index + 1 == brClose.index) {
			parsedCode.tokenList.whitespace(token, NoneAfter);
			parsedCode.tokenList.whitespace(brClose, NoneBefore);
			return;
		}
		var next:TokenInfo = parsedCode.tokenList.getNextToken(brClose);
		if (next != null) {
			switch (next.token.tok) {
				case BrOpen:
					parsedCode.tokenList.whitespace(brClose, After);
				case Binop(OpGt):
					parsedCode.tokenList.whitespace(brClose, NoneAfter);
				case Kwd(_), Const(_):
					parsedCode.tokenList.lineEndAfter(brClose);
				default:
			}
		}
		if (!parsedCode.isOriginalSameLine(token, brClose)) {
			wrapChildOneLineEach(token, brClose, parsedCode, indenter);
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
					wrapChildOneLineEach(token, brClose, parsedCode, indenter);
					return;
				default:
			}
			var length:Int = parsedCode.tokenList.calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token, parsedCode, indenter);
		var type:WrappingType = determineWrapType(config.wrapping.anonType, itemCount, maxLength, totalLength, lineLength);
		switch (type) {
			case OnePerLine:
				wrapChildOneLineEach(token, brClose, parsedCode, indenter);
			case OnePerLineKeep:
				wrapChildOneLineEach(token, brClose, parsedCode, indenter, true);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, brClose, parsedCode, indenter, config.wrapping.maxLineLength);
			case NoWrap:
				noWrap(token, brClose, parsedCode, indenter);
		}
	}

	static function objectLiteralWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		if ((token.children == null) || (token.children.length <= 1)) {
			return;
		}
		if (token.index + 1 == brClose.index) {
			parsedCode.tokenList.whitespace(token, NoneAfter);
			parsedCode.tokenList.whitespace(brClose, NoneBefore);
			return;
		}
		if (!parsedCode.isOriginalSameLine(token, brClose)) {
			wrapChildOneLineEach(token, brClose, parsedCode, indenter);
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
					wrapChildOneLineEach(token, brClose, parsedCode, indenter);
					return;
				default:
			}
			var length:Int = parsedCode.tokenList.calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token, parsedCode, indenter);
		var type:WrappingType = determineWrapType(config.wrapping.objectLiteral, itemCount, maxLength, totalLength, lineLength);
		switch (type) {
			case OnePerLine:
				wrapChildOneLineEach(token, brClose, parsedCode, indenter);
			case OnePerLineKeep:
				wrapChildOneLineEach(token, brClose, parsedCode, indenter, true);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, brClose, parsedCode, indenter, config.wrapping.maxLineLength);
			case NoWrap:
				noWrap(token, brClose, parsedCode, indenter);
				var next:TokenInfo = parsedCode.tokenList.getNextToken(brClose);
				if (next == null) {
					return;
				}
				switch (next.token.tok) {
					case DblDot:
						parsedCode.tokenList.noLineEndAfter(brClose);
					case Dot:
						parsedCode.tokenList.whitespace(brClose, NoneAfter);
					default:
				}
		}
	}

	static function markPWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		var pClose:TokenTree = token.access().firstOf(PClose).token;
		switch (TokenTreeCheckUtils.getPOpenType(token)) {
			case PARAMETER:
				wrapFunctionSignature(token, parsedCode, indenter, config);
			case CALL:
				parsedCode.tokenList.wrapAfter(token, true);
				if (pClose != null) {
					parsedCode.tokenList.wrapBefore(pClose, true);
				}
				for (child in token.children) {
					if (child.is(PClose)) {
						continue;
					}
					var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
					if (lastChild == null) {
						parsedCode.tokenList.wrapAfter(lastChild, true);
					} else {
						parsedCode.tokenList.wrapAfter(lastChild, true);
					}
				}
			case CONDITION:
				parsedCode.tokenList.wrapAfter(token, true);
				if (pClose != null) {
					parsedCode.tokenList.wrapBefore(pClose, true);
				}
			case FORLOOP:
			case EXPRESSION:
		}
	}

	static function arrayWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
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
					atLength += parsedCode.tokenList.calcLength(child);
					continue;
				case BkClose:
					break;
				case Kwd(KwdFor):
					return;
				case Kwd(KwdWhile):
					return;
				default:
					var length:Int = parsedCode.tokenList.calcLength(child);
					totalLength += length;
					if (length > maxLength) {
						maxLength = length;
					}
					itemCount++;
			}
		}

		var lineLength:Int = calcLineLength(token, parsedCode, indenter);
		var type:WrappingType = determineWrapType(config.wrapping.arrayWrap, itemCount, maxLength, totalLength, lineLength);
		switch (type) {
			case OnePerLine:
				wrapChildOneLineEach(token, bkClose, parsedCode, indenter);
			case OnePerLineKeep:
				wrapChildOneLineEach(token, bkClose, parsedCode, indenter, true);
			case EqualNumber:
			case FillLine:
				wrapArrayWithMany(token, bkClose, parsedCode, indenter, config.wrapping.maxLineLength);
			case NoWrap:
				noWrap(token, bkClose, parsedCode, indenter);
		}
		if (atLength > 30) {
			parsedCode.tokenList.lineEndBefore(token);
		}
	}

	public static function noWrap(open:TokenTree, close:TokenTree, parsedCode:ParsedCode, indenter:Indenter) {
		parsedCode.tokenList.whitespace(open, NoneAfter);
		parsedCode.tokenList.noWrappingBetween(open, close);
		for (child in open.children) {
			switch (child.tok) {
				case PClose, BrClose, BkClose:
					continue;
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
						parsedCode.tokenList.whitespace(lastChild, After);
					default:
				}
			}
		}
		parsedCode.tokenList.whitespace(close, NoneBefore);
	}

	public static function wrapChildOneLineEach(open:TokenTree, close:TokenTree, parsedCode:ParsedCode, indenter:Indenter, keepFirst:Bool = false) {
		parsedCode.tokenList.noWrappingBetween(open, close);
		if (!keepFirst) {
			parsedCode.tokenList.lineEndAfter(open);
		}
		for (child in open.children) {
			switch (child.tok) {
				case PClose, BrClose, BkClose:
					if (keepFirst) {
						parsedCode.tokenList.whitespace(child, NoneBefore);
					}
					return;
				case Binop(OpGt):
					if (keepFirst) {
						parsedCode.tokenList.whitespace(child, NoneBefore);
					}
					return;
				case CommentLine(_):
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(child);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(child, prev.token)) {
							parsedCode.tokenList.noLineEndBefore(child);
						}
					}
					parsedCode.tokenList.lineEndAfter(child);
					continue;
				default:
			}
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
			if (lastChild == null) {
				parsedCode.tokenList.lineEndAfter(child);
			} else {
				parsedCode.tokenList.lineEndAfter(lastChild);
			}
		}
	}

	public static function wrapFillLine(open:TokenTree, close:TokenTree, parsedCode:ParsedCode, indenter:Indenter, maxLineLength:Int) {
		parsedCode.tokenList.noWrappingBetween(open, close);
		var indent:Int = indenter.calcIndent(open);
		var lineLength:Int = parsedCode.tokenList.calcLineLengthBefore(open) + indenter.calcAbsoluteIndent(indent);
		for (child in open.children) {
			switch (child.tok) {
				case PClose, BrClose, BkClose:
					parsedCode.tokenList.whitespace(child, NoneBefore);
					return;
				case Binop(OpGt):
					parsedCode.tokenList.whitespace(child, NoneBefore);
					return;
				case CommentLine(_):
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(child);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(child, prev.token)) {
							parsedCode.tokenList.noLineEndBefore(child);
						}
					}
					parsedCode.tokenList.lineEndAfter(child);
					continue;
				default:
			}
			var tokenLength:Int = parsedCode.tokenList.calcLength(child);
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
			if (lastChild == null) {
				lastChild = child;
			}
			lineLength += tokenLength;
			if (lineLength > maxLineLength) {
				parsedCode.tokenList.lineEndBefore(child);
				parsedCode.tokenList.noLineEndAfter(lastChild);
				indent = indenter.calcIndent(child);
				lineLength = tokenLength + indenter.calcAbsoluteIndent(indent);
			} else {
				parsedCode.tokenList.noLineEndAfter(lastChild);
			}
		}
	}

	static function wrapArrayWithMany(bkOpen:TokenTree, bkClose:TokenTree, parsedCode:ParsedCode, indenter:Indenter, maxLineLength:Int) {
		parsedCode.tokenList.noWrappingBetween(bkOpen, bkClose);
		parsedCode.tokenList.lineEndAfter(bkOpen);
		var indent:Int = indenter.calcAbsoluteIndent(indenter.calcIndent(bkOpen.children[0]));
		var lineLength:Int = indent;
		for (child in bkOpen.children) {
			if (child.is(At)) {
				continue;
			}
			if (child.is(BkClose)) {
				continue;
			}
			var length:Int = parsedCode.tokenList.calcLength(child);
			if (length + lineLength > maxLineLength) {
				parsedCode.tokenList.lineEndBefore(child);
				lineLength = length + indent;
			} else {
				var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
				parsedCode.tokenList.whitespace(lastChild, After);
				lineLength += length;
			}
		}
		parsedCode.tokenList.lineEndBefore(bkClose);
	}

	static function calcLineLength(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter):Int {
		if (token == null) {
			return 0;
		}
		var indent:Int = indenter.calcIndent(token);
		return parsedCode.tokenList.calcLineLength(token) + indenter.calcAbsoluteIndent(indent);
	}

	static function wrapFunctionSignature(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
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
				atLength += parsedCode.tokenList.calcLength(child);
				continue;
			}
			if (child.is(PClose)) {
				break;
			}
			var length:Int = parsedCode.tokenList.calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
			itemCount++;
		}
		var lineLength:Int = calcLineLength(token, parsedCode, indenter);
		var type:WrappingType = determineWrapType(config.wrapping.functionSignature, itemCount, maxLength, totalLength, lineLength);
		switch (type) {
			case OnePerLine:
				wrapChildOneLineEach(token, pClose, parsedCode, indenter);
			case OnePerLineKeep:
				wrapChildOneLineEach(token, pClose, parsedCode, indenter, true);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, pClose, parsedCode, indenter, config.wrapping.maxLineLength);
			case NoWrap:
				parsedCode.tokenList.noWrappingBetween(token, pClose);
		}
	}

	static function determineWrapType(config:Array<WrapRule>, itemCount:Int, maxItemLength:Int, totalItemLength:Int, lineLength:Int):WrappingType {
		for (rule in config) {
			if (matchesRule(rule, itemCount, maxItemLength, totalItemLength, lineLength)) {
				return rule.type;
			}
		}
		return NoWrap;
	}

	static function matchesRule(rule:WrapRule, itemCount:Int, maxItemLength:Int, totalItemLength:Int, lineLength:Int):Bool {
		var result:Bool = true;
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
		return result;
	}
}
