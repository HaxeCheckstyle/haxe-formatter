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
				whitespaceAfterWithoutNL: None,
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
				info.whitespaceAfter = None;
				if (prev != null) {
					prev.whitespaceAfter = None;
				}
			case NoneAfter:
				info.whitespaceAfter = None;
			case OnlyAfter:
				if (prev != null) {
					prev.whitespaceAfter = None;
				}
				info.whitespaceAfter = Space;
			case Before:
				if (prev != null) {
					prev.whitespaceAfter = Space;
				}
			case NoneBefore:
				if (prev != null) {
					prev.whitespaceAfter = None;
				}
			case OnlyBefore:
				if (prev != null) {
					prev.whitespaceAfter = Space;
				}
				info.whitespaceAfter = None;
			case After:
				info.whitespaceAfter = Space;
			case Around:
				info.whitespaceAfter = Space;
				if (prev != null) {
					prev.whitespaceAfter = Space;
				}
		}
		if (prev != null && prev.whitespaceAfter != Newline) {
			prev.whitespaceAfterWithoutNL = prev.whitespaceAfter;
		}
		if (info.whitespaceAfter != Newline) {
			info.whitespaceAfterWithoutNL = info.whitespaceAfter;
		}
		#if debugLog
		logAction(pos, token, '$where');
		#end
	}

	public function lineEndAfter(token:TokenTree, ?pos:PosInfos) {
		if (token.index < 0) {
			return;
		}
		var info:TokenInfo = tokens[token.index];
		if (info == null) {
			return;
		}
		#if debugLog
		logAction(pos, token, "NewLine");
		#end
		info.whitespaceAfter = Newline;
	}

	public function lineEndBefore(token:TokenTree, ?pos:PosInfos) {
		var info:TokenInfo = getPreviousToken(token);
		if (info == null) {
			return;
		}
		#if debugLog
		logAction(pos, token, "NewLine");
		#end
		info.whitespaceAfter = Newline;
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
		#if debugLog
		logAction(pos, token, "Space");
		#end
		info.whitespaceAfter = Space; // info.whitespaceAfterWithoutNL;
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
		#if debugLog
		logAction(pos, token, "Space");
		#end
		info.whitespaceAfter = Space; // info.whitespaceAfterWithoutNL;
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
				default:
			}
			if ((nestLevel <= 0) && (info.whitespaceAfter == Newline)) {
				info.whitespaceAfter = info.whitespaceAfterWithoutNL;
				#if debugLog
				logAction(pos, info.token, 'whitespaceAfter: ${info.whitespaceAfterWithoutNL}');
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
			if (currTok.whitespaceAfter == Newline) {
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
			if (info.whitespaceAfter == Newline) {
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
				case Newline:
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
				case Newline:
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
		return info.whitespaceAfter == Newline;
	}

	public function isNewLineAfter(token:TokenTree):Bool {
		var info:TokenInfo = getTokenAt(token.index);
		if (info == null) {
			return false;
		}
		return info.whitespaceAfter == Newline;
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
