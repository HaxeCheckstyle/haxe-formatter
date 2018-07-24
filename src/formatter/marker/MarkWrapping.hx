package formatter.marker;

import formatter.config.WrapConfig;

class MarkWrapping {
	public static function markWrapping(parsedCode:ParsedCode, indenter:Indenter, config:WrapConfig) {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Comma:
					if (config.wrapAfterComma) {
						parsedCode.tokenList.wrapAfter(token, true);
					}
				case Dot:
					if (config.wrapBeforeDot) {
						parsedCode.tokenList.wrapBefore(token, true);
					}
				case BrOpen:
					if (config.wrapAfterOpeningBrace) {
						markBrWrapping(token, parsedCode, config);
					}
				case BkOpen:
					if (config.wrapAfterOpeningBracket) {
						arrayWrapping(token, parsedCode, indenter, config);
					}
				case POpen:
					if (config.wrapAfterOpeningParenthesis) {
						markPWrapping(token, parsedCode, config);
					}
				case Binop(OpAdd):
					if (config.wrapAfterPlus) {
						parsedCode.tokenList.wrapAfter(token, true);
					}
				default:
			}
			return GO_DEEPER;
		});
	}

	static function markBrWrapping(token:TokenTree, parsedCode:ParsedCode, config:WrapConfig) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		switch (TokenTreeCheckUtils.getBrOpenType(token)) {
			case BLOCK:
			case TYPEDEFDECL:
			case OBJECTDECL:
				parsedCode.tokenList.wrapAfter(token, true);
				if (brClose != null) {
					parsedCode.tokenList.wrapBefore(brClose, true);
				}
			case ANONTYPE:
				parsedCode.tokenList.wrapAfter(token, true);
				if (brClose != null) {
					parsedCode.tokenList.wrapBefore(brClose, true);
				}
			case UNKNOWN:
		}
	}

	static function markPWrapping(token:TokenTree, parsedCode:ParsedCode, config:WrapConfig) {
		var pClose:TokenTree = token.access().firstOf(PClose).token;
		switch (TokenTreeCheckUtils.getPOpenType(token)) {
			case PARAMETER:
				parsedCode.tokenList.wrapAfter(token, true);
				if (pClose != null) {
					parsedCode.tokenList.wrapBefore(pClose, true);
				}
			case CALL:
				parsedCode.tokenList.wrapAfter(token, true);
				if (pClose != null) {
					parsedCode.tokenList.wrapBefore(pClose, true);
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

	static function arrayWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:WrapConfig) {
		var bkClose:TokenTree = token.access().firstOf(BkClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		var maxLength:Int = 0;
		var totalLength:Int = 0;
		var atLength:Int = 0;
		for (child in token.children) {
			if (child.is(At)) {
				atLength += calcLength(child, parsedCode);
				continue;
			}
			if (child.is(BkClose)) {
				break;
			}
			var length:Int = calcLength(child, parsedCode);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
		}
		if (atLength > config.arrayMaxInlineAtLength) {
			parsedCode.tokenList.lineEndBefore(token);
		}
		if (totalLength <= config.arrayTotalItemLengthOneLine) {
			parsedCode.tokenList.whitespace(token, NoneAfter);
			parsedCode.tokenList.whitespace(bkClose, NoneBefore);
			return;
		}
		if (maxLength > config.arrayMaxItemLength) {
			wrapArrayOneLineEach(token, bkClose, parsedCode, indenter, config);
			return;
		}
		if (token.children.length - 1 > config.arrayMaxOneLineItems) {
			wrapArrayWithMany(token, bkClose, parsedCode, indenter, config);
			return;
		}
	}

	static function wrapArrayOneLineEach(bkOpen:TokenTree, bkClose:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:WrapConfig) {
		parsedCode.tokenList.lineEndAfter(bkOpen);
		for (child in bkOpen.children) {
			if (child.is(BkClose)) {
				continue;
			}
			var lastChild:TokenTree = MarkLineEnds.lastToken(child);
			if (lastChild == null) {
				parsedCode.tokenList.lineEndAfter(child);
			} else {
				parsedCode.tokenList.lineEndAfter(lastChild);
			}
		}
	}

	static function wrapArrayWithMany(bkOpen:TokenTree, bkClose:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:WrapConfig) {
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
			var length:Int = calcLength(child, parsedCode) + 1;
			if (length + lineLength > config.maxLineLength) {
				parsedCode.tokenList.lineEndBefore(child);
				lineLength = length + indent;
			} else {
				var lastChild:TokenTree = MarkLineEnds.lastToken(child);
				parsedCode.tokenList.whitespace(lastChild, After);
				lineLength += length;
			}
		}
		parsedCode.tokenList.lineEndBefore(bkClose);
	}

	static function calcLength(token:TokenTree, parsedCode:ParsedCode):Int {
		if (token == null) {
			return 0;
		}
		var current:TokenInfo = parsedCode.tokenList.getTokenAt(token.index);
		var length:Int = current.text.length;
		if ((token.children == null) || (token.children.length <= 0)) {
			return length;
		}
		for (child in token.children) {
			length += calcLength(child, parsedCode);
		}
		return length;
	}
}
