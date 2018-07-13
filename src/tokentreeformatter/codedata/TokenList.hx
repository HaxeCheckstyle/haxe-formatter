package tokentreeformatter.codedata;

import tokentreeformatter.config.WhitespacePolicy;

class TokenList {

	public var tokens:Array<TokenInfo>;

	public function new() {
		tokens = [];
	}

	public function buildList(token:TokenTree) {
		if (token.children == null) {
			return;
		}

		for (child in token.children) {
			var index:Int = child.index;
			if (child.index >= tokens.length) {
				fill(child.index - tokens.length);
			}
			tokens[index] = {
				token: child, whitespaceAfter: NONE, emptyLinesAfter: 0, wrapAfter: false, text: null
			};
			buildList(child);
		}
	}

	function fill(count:Int) {
		while (count-- > 0) {
			tokens.push(null);
		}
	}

	public function getTokenAt(index:Int):TokenInfo {
		if (tokens.length <= index) {
			return null;
		}
		return tokens[index];
	}

	public function getPreviousToken(token:TokenTree):TokenInfo {
		if ((token == null) || (token.index <= 0)) {
			return null;
		}
		var prevToken:TokenInfo = null;
		var prevIndex:Int = token.index - 1;
		if (prevIndex >= tokens.length) {
			return null;
		}
		while (prevToken == null) {
			prevToken = tokens[prevIndex--];
			if (prevIndex < 0) {
				return null;
			}
		}
		return prevToken;
	}

	public function getNextToken(token:TokenTree):TokenInfo {
		if ((token == null) || (token.index <= 0)) {
			return null;
		}
		var nextToken:TokenInfo = null;
		var nextIndex:Int = token.index + 1;
		if (nextIndex >= tokens.length) {
			return null;
		}
		while (nextToken == null) {
			nextToken = tokens[nextIndex++];
			if (nextIndex < 0) {
				return null;
			}
		}
		return nextToken;
	}

	public function whitespace(token:TokenTree, where:WhitespacePolicy) {
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		var prev:TokenInfo = null;
		var prevIndex:Int = token.index - 1;
		while (prev == null) {
			if (prevIndex < 0) {
				break;
			}
			prev = tokens[prevIndex--];
		}
		switch (where) {
			case NONE:
				info.whitespaceAfter = NONE;
				if (prev != null) {
					prev.whitespaceAfter = NONE;
				}
			case NONE_AFTER:
				info.whitespaceAfter = NONE;
			case ONLY_AFTER:
				if (prev != null) {
					prev.whitespaceAfter = NONE;
				}
				info.whitespaceAfter = SPACE;
			case BEFORE:
				if (prev != null) {
					prev.whitespaceAfter = SPACE;
				}
			case AFTER:
				info.whitespaceAfter = SPACE;
			case AROUND:
				info.whitespaceAfter = SPACE;
				if (prev != null) {
					prev.whitespaceAfter = SPACE;
				}
		}
	}

	public function lineEndAfter(token:TokenTree) {
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		info.whitespaceAfter = NL;
	}

	public function lineEndBefore(token:TokenTree) {
		var info:TokenInfo = getPreviousToken(token);
		if (info == null) {
			return;
		}
		info.whitespaceAfter = NL;
	}

	public function noLlineEndAfter(token:TokenTree) {
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		info.whitespaceAfter = SPACE;
	}

	public function noLineEndBefore(token:TokenTree) {
		var info:TokenInfo = getPreviousToken(token);
		if (info == null) {
			return;
		}
		info.whitespaceAfter = SPACE;
	}

	public function emptyLinesAfter(token:TokenTree, count:Int) {
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		info.emptyLinesAfter = count;
	}

	public function emptyLinesAfterSubTree(token:TokenTree, count:Int) {
		if (token == null) {
			return;
		}
		var offset:Int = token.getPos().max + 1;
		var tokenInf:TokenInfo = findTokenAtOffset(offset);
		if (tokenInf == null) {
			return;
		}
		tokenInf.emptyLinesAfter = count;
	}

	public function tokenText(token:TokenTree, text:String) {
		var info:TokenInfo = tokens[token.index];
		if (info == null) return;
		info.text = text;
	}

	public function wrapAfter(token:TokenTree, wrap:Bool) {
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		info.wrapAfter = wrap;
	}

	public function wrapBefore(token:TokenTree, wrap:Bool) {
		var prev:TokenInfo = getPreviousToken(token);
		if (prev == null) {
			return;
		}
		prev.wrapAfter = wrap;
	}

	public function findTokenAtOffset(offset:Int):TokenInfo {
		var lastInfo:TokenInfo = null;

		for (info in tokens) {
			if (info == null) {
				continue;
			}
			if (info.token.pos.min >= offset) {
				return lastInfo;
			}
			lastInfo = info;
		}
		return lastInfo;
	}
}