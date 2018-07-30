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
						markBrWrapping(token, parsedCode, indenter, config);
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

	static function markBrWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:WrapConfig) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		switch (TokenTreeCheckUtils.getBrOpenType(token)) {
			case BLOCK:
			case TYPEDEFDECL:
			case OBJECTDECL:
				// parsedCode.tokenList.wrapAfter(token, true);
				// if (brClose != null) {
				// 	parsedCode.tokenList.wrapBefore(brClose, true);
				// }
				objectLiteralWrapping(token, parsedCode, indenter, config.objectLiteral);
			case ANONTYPE:
				anonTypeWrapping(token, parsedCode, indenter, config.anonType);
			case UNKNOWN:
		}
	}

	static function anonTypeWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:AnonTypeWrapping) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		var maxLength:Int = 0;
		var totalLength:Int = 0;
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
		}
		if (totalLength <= config.totalItemLengthOneLine) {
			parsedCode.tokenList.whitespace(token, NoneAfter);
			parsedCode.tokenList.whitespace(brClose, NoneBefore);
			return;
		}
		if (maxLength > config.maxItemLength) {
			wrapChildOneLineEach(token, brClose, parsedCode, indenter);
			return;
		}
		if (token.children.length - 1 > config.maxOneLineItems) {
			wrapChildOneLineEach(token, brClose, parsedCode, indenter);
			return;
		}
	}

	static function objectLiteralWrapping(token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:ObjectLiteralWrapping) {
		var brClose:TokenTree = token.access().firstOf(BrClose).token;
		if ((token.children == null) || (token.children.length <= 0)) {
			return;
		}
		var maxLength:Int = 0;
		var totalLength:Int = 0;
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
		}
		if (totalLength <= config.totalItemLengthOneLine) {
			parsedCode.tokenList.whitespace(token, NoneAfter);
			parsedCode.tokenList.whitespace(brClose, NoneBefore);
			return;
		}
		if (maxLength > config.maxItemLength) {
			wrapChildOneLineEach(token, brClose, parsedCode, indenter);
			return;
		}
		if (token.children.length - 1 > config.maxOneLineItems) {
			wrapChildOneLineEach(token, brClose, parsedCode, indenter);
			return;
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
				atLength += parsedCode.tokenList.calcLength(child);
				continue;
			}
			if (child.is(BkClose)) {
				break;
			}
			var length:Int = parsedCode.tokenList.calcLength(child);
			totalLength += length;
			if (length > maxLength) {
				maxLength = length;
			}
		}
		if (atLength > config.arrayWrap.maxInlineAtLength) {
			parsedCode.tokenList.lineEndBefore(token);
		}
		if (totalLength <= config.arrayWrap.totalItemLengthOneLine) {
			parsedCode.tokenList.whitespace(token, NoneAfter);
			parsedCode.tokenList.whitespace(bkClose, NoneBefore);
			return;
		}
		if (maxLength > config.arrayWrap.maxItemLength) {
			wrapChildOneLineEach(token, bkClose, parsedCode, indenter);
			return;
		}
		if (token.children.length - 1 > config.arrayWrap.maxOneLineItems) {
			wrapArrayWithMany(token, bkClose, parsedCode, indenter, config.maxLineLength);
			return;
		}
	}

	public static function wrapChildOneLineEach(bkOpen:TokenTree, bkClose:TokenTree, parsedCode:ParsedCode, indenter:Indenter) {
		parsedCode.tokenList.lineEndAfter(bkOpen);
		for (child in bkOpen.children) {
			switch (child.tok) {
				case BkClose:
					continue;
				case BrClose:
					continue;
				case CommentLine(_):
					var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(child);
					if (prev != null) {
						if (parsedCode.isOriginalSameLine(child, prev.token)) {
							parsedCode.tokenList.noLineEndBefore(child);
						}
					}
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

	static function wrapArrayWithMany(bkOpen:TokenTree, bkClose:TokenTree, parsedCode:ParsedCode, indenter:Indenter, maxLineLength:Int) {
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
			var length:Int = parsedCode.tokenList.calcLength(child) + 1;
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
}
