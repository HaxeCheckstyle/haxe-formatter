package formatter.codedata;

import formatter.codedata.FormatterInputData;
import formatter.config.WrapConfig;
import formatter.marker.Indenter;

class CodeLines {
	static inline var FORMATTER_OFF:String = " @formatter:off";
	static inline var FORMATTER_ON:String = " @formatter:on";

	var indenter:Indenter;
	var parsedCode:ParsedCode;
	var range:FormatterInputRange;
	var posRange:FormatterInputRange;
	var newLineAfterRange:Bool;

	public var lines(default, null):Array<CodeLine>;

	public function new(parsedCode:ParsedCode, indenter:Indenter, ?range:FormatterInputRange) {
		lines = [];
		this.indenter = indenter;
		this.parsedCode = parsedCode;
		this.range = null;
		this.posRange = range;
		this.newLineAfterRange = false;
		if (range != null) {
			var start:Null<TokenInfo> = parsedCode.tokenList.getTokenAtOffset(range.startPos);
			var end:Null<TokenInfo> = parsedCode.tokenList.getTokenAtOffset(range.endPos);
			if ((end != null) && (range.endPos - 1 < end.token.pos.min)) {
				end = parsedCode.tokenList.getPreviousToken(end.token);
			}
			if ((start != null) && (end != null)) {
				this.range = {startPos: start.token.index, endPos: end.token.index};
			}
		}
		buildLines();
	}

	function buildLines() {
		var line:Null<CodeLine> = null;
		var index:Int = 0;
		while (index < parsedCode.tokenList.tokens.length) {
			if (range != null) {
				if (index > range.endPos) {
					break;
				}
			}
			var tokenInfo:TokenInfo = parsedCode.tokenList.getTokenAt(index);
			if (tokenInfo == null) {
				index++;
				continue;
			}
			switch (tokenInfo.token.tok) {
				case CommentLine(FORMATTER_OFF):
					line = null;
					index = skipFormatterOff(index);
					continue;
				default:
			}
			if (range != null) {
				if (index < range.startPos) {
					index++;
					continue;
				}
			}
			if (line == null) {
				line = new CodeLine(indenter.calcIndent(tokenInfo.token) + tokenInfo.additionalIndent);
				lines.push(line);
			}
			if ((range != null) && (index == range.endPos)) {
				if ((posRange.endPos > tokenInfo.token.pos.max) && (tokenInfo.whitespaceAfter == Newline)) {
					newLineAfterRange = true;
				}
				if ((posRange.endPos >= tokenInfo.token.pos.min) && (posRange.endPos < tokenInfo.token.pos.max)) {
					tokenInfo.text = tokenInfo.text.substr(0, posRange.endPos - tokenInfo.token.pos.min);
				}
			}
			line.addToken(tokenInfo, parsedCode.lineSeparator);
			if (tokenInfo.whitespaceAfter == Newline) {
				line = null;
			}
			index++;
		}
	}

	function skipFormatterOff(index:Int):Int {
		var startIndex:Int = index++;
		var startInfo:TokenInfo = parsedCode.tokenList.getTokenAt(startIndex);
		var startLine:Int = parsedCode.getLinePos(startInfo.token.pos.min).line;

		while (index < parsedCode.tokenList.tokens.length) {
			var endIndex:Int = index++;
			var tokenInfo:TokenInfo = parsedCode.tokenList.getTokenAt(endIndex);
			if (tokenInfo == null) {
				continue;
			}
			if (range != null) {
				if (endIndex < range.startPos) {
					continue;
				}
				if (endIndex == range.startPos) {
					startInfo = parsedCode.tokenList.getTokenAt(endIndex);
					startLine = parsedCode.getLinePos(startInfo.token.pos.min).line;
				}
				if (endIndex >= range.endPos) {
					copyVerbatimChars(startInfo.token.pos.min, tokenInfo.token.pos.max);
					return index;
				}
			}
			switch (tokenInfo.token.tok) {
				case CommentLine(FORMATTER_ON):
					if (range != null) {
						if (startIndex < range.startPos) {
							copyVerbatimChars(startInfo.token.pos.min, tokenInfo.token.pos.max);
							return index;
						}
					}
					var endLine:Int = parsedCode.getLinePos(tokenInfo.token.pos.max).line;
					copyVerbatimLines(startLine, endLine);
					return index;
				default:
			}
		}
		var endLine:Int = parsedCode.lines.length - 1;
		copyVerbatimLines(startLine, endLine);
		return index;
	}

	function copyVerbatimLines(startLine:Int, endLine:Int) {
		var startOffs:Int = parsedCode.linesIdx[startLine].l;
		var endOffs:Int = parsedCode.linesIdx[endLine].r;
		var content:String = parsedCode.getString(startOffs, endOffs);
		if (endLine < parsedCode.lines.length - 1) {
			content = content.rtrim();
		}
		lines.push(new VerbatimCodeLine(content));
	}

	function copyVerbatimChars(startPos:Int, endPos:Int) {
		var content:String = parsedCode.getString(startPos, endPos);
		lines.push(new VerbatimCodeLine(content));
	}

	public function applyWrapping(config:WrapConfig) {
		var wrappedLines:Array<CodeLine> = [];

		for (line in lines) {
			var wrappedCode:Array<CodeLine> = line.applyWrapping(config, parsedCode, indenter);
			wrappedLines = wrappedLines.concat(wrappedCode);
		}
		lines = wrappedLines;
	}

	public function print(lineSeparator:String):String {
		var prefix:String = "";
		if (parsedCode.tokenList.leadingEmptyLInes > 0) {
			prefix = "".lpad(lineSeparator, lineSeparator.length * parsedCode.tokenList.leadingEmptyLInes);
		}
		var rangeNewLine:String = "";
		if (range != null) {
			if (range.startPos > 0) {
				prefix = "";
			}
			if (newLineAfterRange) {
				rangeNewLine = lineSeparator;
			}
			if (lines.length > 0) {
				var line:CodeLine = lines[lines.length - 1];
				line.emptyLinesAfter = 0;
			}
		}
		return prefix + lines.map(function(line) return line.print(indenter, lineSeparator)).join(lineSeparator) + rangeNewLine;
	}
}
