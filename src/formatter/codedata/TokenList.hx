package formatter.codedata;

import haxe.PosInfos;
#if debugLog
import sys.io.File;
import sys.io.FileOutput;
#end
import formatter.config.WhitespacePolicy;

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
			if ((index < 0) || (child.inserted)) {
				continue;
			}
			if (child.index >= tokens.length) {
				fill(child.index - tokens.length);
			}
			tokens[index] = {
				token: child,
				whitespaceAfter: None,
				emptyLinesAfter: 0,
				wrapAfter: false,
				text: null,
				additionalIndent: 0
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
		if (index < 0) {
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

	public function whitespace(token:TokenTree, where:WhitespacePolicy, ?pos:PosInfos) {
		if (token.index < 0) {
			return;
		}
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
		if ((prev != null) && needsLineBreak(prev.token)) {
			prev = null;
		}
		switch (where) {
			case None:
				applyWhitespace(info, None);
				applyWhitespace(prev, None);
			case NoneAfter:
				applyWhitespace(info, None);
			case OnlyAfter:
				applyWhitespace(prev, None);
				applyWhitespace(info, Space);
			case Before:
				applyWhitespace(prev, Space);
			case NoneBefore:
				applyWhitespace(prev, None);
			case OnlyBefore:
				applyWhitespace(prev, Space);
				applyWhitespace(info, None);
			case After:
				applyWhitespace(info, Space);
			case Around:
				applyWhitespace(info, Space);
				applyWhitespace(prev, Space);
		}
		#if debugLog
		logAction(pos, token, '$where');
		#end
	}

	function applyWhitespace(info:TokenInfo, policy:WhitespaceAfterType) {
		if (info == null) {
			return;
		}
		switch (info.whitespaceAfter) {
			case None:
				info.whitespaceAfter = policy;
			case Newline:
				switch (policy) {
					case None:
					case Newline:
					case Space:
						info.whitespaceAfter = SpaceOrNewline;
					case SpaceOrNewline:
				}
			case Space:
				switch (policy) {
					case None:
						info.whitespaceAfter = None;
					case Newline:
						info.whitespaceAfter = SpaceOrNewline;
					case Space:
					case SpaceOrNewline:
				}
			case SpaceOrNewline:
				switch (policy) {
					case None:
						info.whitespaceAfter = Newline;
					case Newline:
					case Space:
					case SpaceOrNewline:
				}
		}
	}

	public function lineEndAfter(token:TokenTree, ?pos:PosInfos) {
		if (token.index < 0) {
			return;
		}
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}

		switch (info.whitespaceAfter) {
			case None:
				#if debugLog
				logAction(pos, token, "NewLine");
				#end
				info.whitespaceAfter = Newline;
			case Newline:
			case Space:
				#if debugLog
				logAction(pos, token, "SpaceOrNewline");
				#end
				info.whitespaceAfter = SpaceOrNewline;
			case SpaceOrNewline:
		}
	}

	public function lineEndBefore(token:TokenTree, ?pos:PosInfos) {
		var info:TokenInfo = getPreviousToken(token);
		if (info == null) {
			return;
		}
		switch (info.whitespaceAfter) {
			case None:
				#if debugLog
				logAction(pos, token, "NewLine");
				#end
				info.whitespaceAfter = Newline;
			case Newline:
			case Space:
				#if debugLog
				logAction(pos, token, "SpaceOrNewline");
				#end
				info.whitespaceAfter = SpaceOrNewline;
			case SpaceOrNewline:
		}
	}

	function needsLineBreak(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		switch (token.tok) {
			case CommentLine(_):
				return true;
			default:
		}
		return false;
	}

	public function noLineEndAfter(token:TokenTree, ?pos:PosInfos) {
		if (token.index < 0) {
			return;
		}
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		if (needsLineBreak(info.token)) {
			info.whitespaceAfter = Newline;
			return;
		}
		switch (info.whitespaceAfter) {
			case None:
				return;
			case Newline:
				#if debugLog
				logAction(pos, token, "None");
				#end
				info.whitespaceAfter = None;
			case Space, SpaceOrNewline:
				#if debugLog
				logAction(pos, token, "Space");
				#end
				info.whitespaceAfter = Space;
		}
	}

	public function noLineEndBefore(token:TokenTree, ?pos:PosInfos) {
		var info:TokenInfo = getPreviousToken(token);
		if (info == null) {
			return;
		}
		if (needsLineBreak(info.token)) {
			info.whitespaceAfter = Newline;
			return;
		}
		switch (info.whitespaceAfter) {
			case None:
				return;
			case Newline:
				#if debugLog
				logAction(pos, token, "None");
				#end
				info.whitespaceAfter = None;
			case Space, SpaceOrNewline:
				#if debugLog
				logAction(pos, token, "Space");
				#end
				info.whitespaceAfter = Space;
		}
	}

	public function emptyLinesAfter(token:TokenTree, count:Int, ?pos:PosInfos) {
		if (token.index < 0) {
			return;
		}
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		#if debugLog
		logAction(pos, token, '$count');
		#end
		info.emptyLinesAfter = count;
	}

	public function emptyLinesBefore(token:TokenTree, count:Int, ?pos:PosInfos) {
		var info:TokenInfo = getPreviousToken(token);
		if (info == null) {
			return;
		}
		#if debugLog
		logAction(pos, token, '$count');
		#end
		info.emptyLinesAfter = count;
	}

	public function emptyLinesAfterSubTree(token:TokenTree, count:Int, ?pos:PosInfos) {
		var lastToken:TokenTree = TokenTreeCheckUtils.getLastToken(token);
		if (lastToken == null) {
			return;
		}
		var info:TokenInfo = tokens[lastToken.index];
		if (info == null) {
			return;
		}
		#if debugLog
		logAction(pos, lastToken, '$count');
		#end
		info.emptyLinesAfter = count;
	}

	public function tokenText(token:TokenTree, text:String) {
		if (token.index < 0) {
			return;
		}
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		info.text = text;
	}

	public function wrapAfter(token:TokenTree, wrap:Bool, ?pos:PosInfos) {
		if (token.index < 0) {
			return;
		}
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		#if debugLog
		logAction(pos, token, '$wrap');
		#end
		info.wrapAfter = wrap;
	}

	public function wrapBefore(token:TokenTree, wrap:Bool, ?pos:PosInfos) {
		var prev:TokenInfo = getPreviousToken(token);
		if (prev == null) {
			return;
		}
		#if debugLog
		logAction(pos, token, '$wrap');
		#end
		prev.wrapAfter = wrap;
	}

	public function noWrappingBetween(tokenStart:TokenTree, tokenEnd:TokenTree, ?pos:PosInfos) {
		if ((tokenStart == null) || (tokenEnd == null)) {
			return;
		}
		var nestLevel:Int = 0;
		for (index in tokenStart.index...tokenEnd.index) {
			var info:TokenInfo = tokens[index];
			if (info == null) {
				continue;
			}
			info.wrapAfter = false;
			switch (info.token.tok) {
				case BrOpen, BkOpen:
					if (index != tokenStart.index) {
						nestLevel++;
					}
				case BrClose, BkClose:
					nestLevel--;
				case CommentLine(_):
					continue;
				default:
			}
			if (nestLevel <= 0) {
				switch (info.whitespaceAfter) {
					case None:
					case Space:
					case Newline:
						info.whitespaceAfter = None;
					case SpaceOrNewline:
						info.whitespaceAfter = Space;
				}
				#if debugLog
				logAction(pos, info.token, 'whitespaceAfter: ${info.whitespaceAfter}');
				#end
			}
		}
	}

	public function additionalIndent(token:TokenTree, indent:Null<Int>, ?pos:PosInfos) {
		if (indent == null) {
			return;
		}
		if (token.index < 0) {
			return;
		}
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		#if debugLog
		logAction(pos, token, '$indent');
		#end
		info.additionalIndent = indent;
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

	public function isSameLine(first:TokenTree, second:TokenTree):Bool {
		var startIndex:Int = first.index;
		var endIndex:Int = second.index;
		if (startIndex == endIndex) {
			return true;
		}
		if ((startIndex < 0) || (endIndex < 0)) {
			return false;
		}

		if (startIndex > endIndex) {
			startIndex = second.index;
			endIndex = first.index;
		}
		while (startIndex < endIndex) {
			var currTok:TokenInfo = tokens[startIndex++];
			if (currTok == null) {
				continue;
			}
			if ((currTok.whitespaceAfter == Newline) || (currTok.whitespaceAfter == SpaceOrNewline)) {
				return false;
			}
		}
		return true;
	}

	public function calcLength(token:TokenTree):Int {
		if (token == null) {
			return 0;
		}
		if (token.index < 0) {
			return 0;
		}
		var current:TokenInfo = tokens[token.index];
		if (current == null) {
			return 0;
		}
		var spaceAdd:Int = 0;
		if (current.whitespaceAfter == Space) {
			spaceAdd = 1;
		}
		if (current.text == null) {
			current.text = '${current.token}';
		}
		var length:Int = current.text.length + spaceAdd;
		if ((token.children == null) || (token.children.length <= 0)) {
			return length;
		}
		for (child in token.children) {
			length += calcLength(child);
		}
		return length;
	}

	public function calcLengthBetween(tokenStart:TokenTree, tokenEnd:TokenTree):Int {
		if ((tokenStart == null) || (tokenEnd == null)) {
			return 0;
		}
		if ((tokenStart.index < 0) || (tokenEnd.index < 0)) {
			return 0;
		}
		var length:Int = 0;
		for (index in tokenStart.index...tokenEnd.index) {
			var current:TokenInfo = tokens[index];
			if (current == null) {
				continue;
			}
			if (current.text == null) {
				current.text = '${current.token}';
			}
			length += current.text.length;
			if (current.whitespaceAfter == Space) {
				length++;
			}
		}
		return length;
	}

	public function calcLineLength(token:TokenTree):Int {
		if (token == null) {
			return 0;
		}
		if (token.index < 0) {
			return 0;
		}
		var start:Int = token.index - 1;
		while (true) {
			if (start < 0) {
				break;
			}
			var info:TokenInfo = tokens[start--];
			if (info == null) {
				continue;
			}
			if ((info.whitespaceAfter == Newline) || (info.whitespaceAfter == SpaceOrNewline)) {
				start += 2;
				break;
			}
		}
		var length:Int = 0;
		while (true) {
			if (start >= tokens.length) {
				break;
			}
			var info:TokenInfo = tokens[start++];
			if (info == null) {
				continue;
			}
			length += info.text.length;
			switch (info.whitespaceAfter) {
				case None:
				case Newline, SpaceOrNewline:
					break;
				case Space:
					length += 1;
			}
		}
		return length;
	}

	public function calcLineLengthBefore(token:TokenTree):Int {
		if (token == null) {
			return 0;
		}
		if (token.index < 0) {
			return 0;
		}
		var start:Int = token.index - 1;
		var length:Int = 0;
		while (true) {
			if (start < 0) {
				break;
			}
			var info:TokenInfo = tokens[start--];
			if (info == null) {
				continue;
			}
			switch (info.whitespaceAfter) {
				case None:
				case Newline, SpaceOrNewline:
					break;
				case Space:
					length += 1;
			}
			length += info.text.length;
		}
		return length;
	}

	public function isNewLineBefore(token:TokenTree):Bool {
		var info:TokenInfo = getPreviousToken(token);
		if (info == null) {
			return false;
		}
		return (info.whitespaceAfter == Newline || info.whitespaceAfter == SpaceOrNewline);
	}

	public function isNewLineAfter(token:TokenTree):Bool {
		var info:TokenInfo = getTokenAt(token.index);
		if (info == null) {
			return false;
		}
		return (info.whitespaceAfter == Newline || info.whitespaceAfter == SpaceOrNewline);
	}

	public function isSameLineBetween(tokenStart:TokenTree, tokenEnd:TokenTree, exclude:Bool):Bool {
		if ((tokenStart == null) || (tokenEnd == null)) {
			return true;
		}
		var start:Int = tokenStart.index;
		var end:Int = tokenEnd.index;
		if (exclude) {
			start++;
		}
		for (index in start...end) {
			var info:TokenInfo = tokens[index];
			if (info == null) {
				continue;
			}
			if ((info.whitespaceAfter == Newline) || (info.whitespaceAfter == SpaceOrNewline)) {
				return false;
			}
		}
		return true;
	}

	#if debugLog
	function logAction(callerPos:PosInfos, token:TokenTree, what:String, ?pos:PosInfos) {
		var text:String = '${callerPos.fileName}:${callerPos.lineNumber}:${callerPos.methodName} [${pos.methodName} ($what)] on `${token}` (${token.pos})';
		var file:FileOutput = File.append("hxformat.log", false);
		file.writeString(text + "\n");
		file.close();
	}
	#end
}
