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
				case Binop(OpArrow), Arrow:
					parsedCode.tokenList.wrapAfter(token, true);
				case CommentLine(_):
					parsedCode.tokenList.wrapBefore(token, false);
				default:
			}
			return GO_DEEPER;
		});

		markMethodChaining(parsedCode, indenter, config);
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
					var info:TokenInfo = parsedCode.tokenList.getTokenAt(close.index);
					if ((info.whitespaceAfter != Newline) && (info.whitespaceAfter != SpaceOrNewline)) {
						parsedCode.tokenList.whitespace(close, After);
					}
				case Semicolon, Dot, POpen:
					parsedCode.tokenList.whitespace(close, NoneAfter);
				case Binop(OpGt):
					parsedCode.tokenList.whitespace(close, NoneAfter);
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
					wrapChildOneLineEach(token, close, parsedCode, indenter, 0);
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
		var rule:WrapRule = determineWrapType(config.wrapping.typeParameter, itemCount, maxLength, totalLength, lineLength);
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, close, parsedCode, indenter, rule.additionalIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, close, parsedCode, indenter, rule.additionalIndent, true);
			case Keep:
				keep(token, close, parsedCode, indenter, rule.additionalIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, close, parsedCode, indenter, config.wrapping.maxLineLength, rule.additionalIndent);
			case NoWrap:
				noWrap(token, close, parsedCode, indenter);
		}
	}

	static function markBrWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		switch (TokenTreeCheckUtils.getBrOpenType(token)) {
			case BLOCK:
			case TYPEDEFDECL:
				typedefWrapping(token, parsedCode, indenter, config);
			case OBJECTDECL:
				objectLiteralWrapping(token, parsedCode, indenter, config);
			case ANONTYPE:
				anonTypeWrapping(token, parsedCode, indenter, config);
			case UNKNOWN:
		}
	}

	static function typedefWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		if (parsedCode.isOriginalSameLine(token, brClose)) {
			noWrap(token, brClose, parsedCode, indenter);
			return;
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
					parsedCode.tokenList.noLineEndAfter(brClose);
				case Binop(OpGt):
					parsedCode.tokenList.noLineEndAfter(brClose);
					parsedCode.tokenList.whitespace(brClose, NoneAfter);
				case Const(CIdent("from")), Const(CIdent("to")):
					parsedCode.tokenList.noLineEndAfter(brClose);
				case Kwd(_), Const(_):
					parsedCode.tokenList.lineEndAfter(brClose);
				default:
			}
		}
		if (!parsedCode.isOriginalSameLine(token, brClose)) {
			wrapChildOneLineEach(token, brClose, parsedCode, indenter, 0);
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
					wrapChildOneLineEach(token, brClose, parsedCode, indenter, 0);
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
		var rule:WrapRule = determineWrapType(config.wrapping.anonType, itemCount, maxLength, totalLength, lineLength);
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, brClose, parsedCode, indenter, rule.additionalIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, brClose, parsedCode, indenter, rule.additionalIndent, true);
			case Keep:
				keep(token, brClose, parsedCode, indenter, rule.additionalIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, brClose, parsedCode, indenter, config.wrapping.maxLineLength, rule.additionalIndent);
			case NoWrap:
				noWrap(token, brClose, parsedCode, indenter);
				var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
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
			wrapChildOneLineEach(token, brClose, parsedCode, indenter, 0);
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
					wrapChildOneLineEach(token, brClose, parsedCode, indenter, 0);
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
		var rule:WrapRule = determineWrapType(config.wrapping.objectLiteral, itemCount, maxLength, totalLength, lineLength);
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, brClose, parsedCode, indenter, rule.additionalIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, brClose, parsedCode, indenter, rule.additionalIndent, true);
			case Keep:
				keep(token, brClose, parsedCode, indenter, rule.additionalIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, brClose, parsedCode, indenter, config.wrapping.maxLineLength, rule.additionalIndent);
			case NoWrap:
				noWrap(token, brClose, parsedCode, indenter);
				var next:TokenInfo = parsedCode.tokenList.getNextToken(brClose);
				if (next != null) {
					switch (next.token.tok) {
						case DblDot:
							parsedCode.tokenList.noLineEndAfter(brClose);
						case Dot, Comma:
							parsedCode.tokenList.whitespace(brClose, NoneAfter);
						default:
					}
				}
				var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
				if (prev != null) {
					switch (prev.token.tok) {
						case Kwd(_):
							parsedCode.tokenList.noLineEndBefore(token);
							parsedCode.tokenList.whitespace(token, Before);
						case POpen:
							parsedCode.tokenList.noLineEndBefore(token);
						default:
					}
				}
		}
	}

	static function markPWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		var pClose:TokenTree = token.access().firstOf(PClose).token;
		switch (TokenTreeCheckUtils.getPOpenType(token)) {
			case AT:
				if (token.children != null) {
					if (parsedCode.tokenList.isSameLineBetween(token, pClose, true)) {
						parsedCode.tokenList.noWrappingBetween(token, pClose);
					} else {
						parsedCode.tokenList.wrapAfter(token, true);
						if (pClose != null) {
							parsedCode.tokenList.wrapBefore(pClose, false);
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
					}
				}
			case PARAMETER:
				wrapFunctionSignature(token, parsedCode, indenter, config);
			case CALL:
				parsedCode.tokenList.wrapBefore(token, true);
				if (token.children != null) {
					if (parsedCode.tokenList.isSameLineBetween(token, pClose, true)) {
						parsedCode.tokenList.noWrappingBetween(token, pClose);
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
				}
				if (pClose != null) {
					parsedCode.tokenList.wrapBefore(pClose, false);
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
				case CommentLine(_):
					wrapChildOneLineEach(token, bkClose, parsedCode, indenter, 0);
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
		var rule:WrapRule = determineWrapType(config.wrapping.arrayWrap, itemCount, maxLength, totalLength, lineLength);
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, bkClose, parsedCode, indenter, rule.additionalIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, bkClose, parsedCode, indenter, rule.additionalIndent, true);
			case Keep:
				keep(token, bkClose, parsedCode, indenter, rule.additionalIndent);
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
		var colon:TokenTree = open.access().is(BrOpen).parent().is(DblDot).token;
		if (colon != null) {
			var type:ColonType = TokenTreeCheckUtils.getColonType(colon);
			switch (type) {
				case SWITCH_CASE:
				case TYPE_HINT:
				case TYPE_CHECK:
				case TERNARY:
				case OBJECT_LITERAL:
					parsedCode.tokenList.noLineEndBefore(open);
				case AT:
				case UNKNOWN:
			}
		}
		parsedCode.tokenList.noWrappingBetween(open, close);
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
						parsedCode.tokenList.noLineEndAfter(lastChild);
					default:
				}
			}
		}
		parsedCode.tokenList.noLineEndBefore(close);
	}

	public static function keep(open:TokenTree, close:TokenTree, parsedCode:ParsedCode, indenter:Indenter, addIndent:Int) {
		parsedCode.tokenList.noWrappingBetween(open, close);
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
			if (parsedCode.isOriginalNewlineBefore(child)) {
				parsedCode.tokenList.lineEndBefore(child);
				parsedCode.tokenList.additionalIndent(child, addIndent);
			} else {
				parsedCode.tokenList.noLineEndBefore(child);
				parsedCode.tokenList.wrapBefore(child, false);
			}
		}
		parsedCode.tokenList.noLineEndBefore(close);
	}

	public static function wrapChildOneLineEach(open:TokenTree, close:TokenTree, parsedCode:ParsedCode, indenter:Indenter, additionalIndent:Int = 0,
			keepFirst:Bool = false) {
		if (!keepFirst) {
			parsedCode.tokenList.lineEndAfter(open);
		}
		for (child in open.children) {
			switch (child.tok) {
				case PClose, BrClose, BkClose:
					if (keepFirst) {
						parsedCode.tokenList.noLineEndBefore(child);
					}
					return;
				case Binop(OpGt):
					if (keepFirst) {
						parsedCode.tokenList.noLineEndBefore(child);
					}
					return;
				case Sharp(_):
					wrapChildOneLineEachSharp(child, parsedCode, indenter, additionalIndent, keepFirst);
				case CommentLine(_):
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(child);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(child, prev.token)) {
							parsedCode.tokenList.noLineEndBefore(child);
						}
					}
					parsedCode.tokenList.lineEndAfter(child);
					parsedCode.tokenList.additionalIndent(child, additionalIndent);
					continue;
				default:
					parsedCode.tokenList.additionalIndent(child, additionalIndent);
			}
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(child);
			if (lastChild == null) {
				parsedCode.tokenList.lineEndAfter(child);
			} else {
				parsedCode.tokenList.lineEndAfter(lastChild);
			}
		}
	}

	public static function wrapChildOneLineEachSharp(sharp:TokenTree, parsedCode:ParsedCode, indenter:Indenter, additionalIndent:Int = 0,
			keepFirst:Bool = false) {
		var children:Array<TokenTree> = sharp.children;
		var skipFirst:Bool = false;
		parsedCode.tokenList.lineEndBefore(sharp);
		switch (sharp.tok) {
			case Sharp(MarkLineEnds.SHARP_IF):
				parsedCode.tokenList.lineEndAfter(TokenTreeCheckUtils.getLastToken(sharp.getFirstChild()));
				skipFirst = true;
			case Sharp(MarkLineEnds.SHARP_ELSE_IF):
				parsedCode.tokenList.lineEndAfter(TokenTreeCheckUtils.getLastToken(sharp.getFirstChild()));
				skipFirst = true;
			case Sharp(MarkLineEnds.SHARP_ELSE):
				parsedCode.tokenList.lineEndAfter(sharp);
			case Sharp(MarkLineEnds.SHARP_END):
				parsedCode.tokenList.lineEndAfter(sharp);
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
						parsedCode.tokenList.whitespace(child, NoneBefore);
					}
					return;
				case Binop(OpGt):
					if (keepFirst) {
						parsedCode.tokenList.whitespace(child, NoneBefore);
					}
					return;
				case Sharp(_):
					wrapChildOneLineEachSharp(child, parsedCode, indenter, additionalIndent, keepFirst);
				case CommentLine(_):
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(child);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(child, prev.token)) {
							parsedCode.tokenList.noLineEndBefore(child);
						}
					}
					parsedCode.tokenList.lineEndAfter(child);
					parsedCode.tokenList.additionalIndent(child, additionalIndent);
					continue;
				default:
					parsedCode.tokenList.additionalIndent(child, additionalIndent);
			}
		}
	}

	public static function wrapFillLine(open:TokenTree, close:TokenTree, parsedCode:ParsedCode, indenter:Indenter, maxLineLength:Int,
			additionalIndent:Int = 0) {
		parsedCode.tokenList.noWrappingBetween(open, close);
		var indent:Int = indenter.calcIndent(open);
		var lineLength:Int = parsedCode.tokenList.calcLineLengthBefore(open) + indenter.calcAbsoluteIndent(indent + additionalIndent);
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
					parsedCode.tokenList.additionalIndent(child, additionalIndent);
					continue;
				default:
					parsedCode.tokenList.additionalIndent(child, additionalIndent);
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
				break;
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
		var emptyBody:Bool = hasEmptyFunctionBody(token);
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
		var rule:WrapRule = determineWrapType(config.wrapping.functionSignature, itemCount, maxLength, totalLength, lineLength);
		var addIndent:Int = rule.additionalIndent;
		if (emptyBody) {
			addIndent = 0;
		}
		switch (rule.type) {
			case OnePerLine:
				wrapChildOneLineEach(token, pClose, parsedCode, indenter, addIndent);
			case OnePerLineAfterFirst:
				wrapChildOneLineEach(token, pClose, parsedCode, indenter, addIndent, true);
			case Keep:
				keep(token, pClose, parsedCode, indenter, addIndent);
			case EqualNumber:
			case FillLine:
				wrapFillLine(token, pClose, parsedCode, indenter, config.wrapping.maxLineLength, addIndent);
			case NoWrap:
				parsedCode.tokenList.noWrappingBetween(token, pClose);
		}
	}

	static function hasEmptyFunctionBody(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		var body:TokenTree = token.nextSibling;
		if (body == null) {
			return false;
		}
		if (body.is(DblDot)) {
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

	static function determineWrapType(config:Array<WrapRule>, itemCount:Int, maxItemLength:Int, totalItemLength:Int, lineLength:Int):WrapRule {
		for (rule in config) {
			if (matchesRule(rule, itemCount, maxItemLength, totalItemLength, lineLength)) {
				return rule;
			}
		}
		return {
			conditions: [],
			type: NoWrap,
			additionalIndent: 0
		};
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

	static function markMethodChaining(parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		var chainStarts:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Dot:
					parsedCode.tokenList.wrapBefore(token, true);
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
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
			markSingleMethodChain(chainStart, parsedCode, indenter, config);
		}
	}

	static function markSingleMethodChain(chainStart:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		var chainedCalls:Array<TokenTree> = chainStart.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Dot:
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
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
			var length:Int = parsedCode.tokenList.calcLengthBetween(prevChainElement, chainElement);
			prevChainElement = chainElement;
			if (length > maxLength) {
				maxLength = length;
			}
			totalLength += length;
		}
		var itemCount:Int = chainedCalls.length;
		var lineLength:Int = calcLineLength(chainStart, parsedCode, indenter);
		var rule:WrapRule = determineWrapType(config.wrapping.methodChain, itemCount, maxLength, totalLength, lineLength);
		var addIndent:Int = rule.additionalIndent;
		if (addIndent == null) {
			addIndent = 0;
		}
		switch (rule.type) {
			case OnePerLine:
				for (index in 0...chainedCalls.length) {
					var element:TokenTree = chainedCalls[index];
					parsedCode.tokenList.lineEndBefore(element);
					if (index == 0) {
						parsedCode.tokenList.additionalIndent(element, addIndent + 1);
					} else {
						parsedCode.tokenList.additionalIndent(element, addIndent);
					}
				}
			case OnePerLineAfterFirst:
				parsedCode.tokenList.noLineEndBefore(chainStart);
				for (index in 1...chainedCalls.length) {
					var element:TokenTree = chainedCalls[index];
					parsedCode.tokenList.lineEndBefore(element);
					parsedCode.tokenList.additionalIndent(element, addIndent);
				}
			case NoWrap:
				for (element in chainedCalls) {
					parsedCode.tokenList.noLineEndBefore(element);
					parsedCode.tokenList.wrapBefore(element, false);
				}
			case Keep:
				for (index in 0...chainedCalls.length) {
					var element:TokenTree = chainedCalls[index];
					if (parsedCode.isOriginalNewlineBefore(element)) {
						parsedCode.tokenList.lineEndBefore(element);
						if (index == 0) {
							parsedCode.tokenList.additionalIndent(element, addIndent + 1);
						} else {
							parsedCode.tokenList.additionalIndent(element, addIndent);
						}
					} else {
						parsedCode.tokenList.noLineEndBefore(element);
						parsedCode.tokenList.wrapBefore(element, false);
					}
				}
			case EqualNumber:
			case FillLine:
		}
	}
}
