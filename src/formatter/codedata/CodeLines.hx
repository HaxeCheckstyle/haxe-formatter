package formatter.codedata;

import formatter.config.WrapConfig;
import formatter.marker.Indenter;

class CodeLines {
	static inline var FORMATTER_OFF:String = " @formatter:off";
	static inline var FORMATTER_ON:String = " @formatter:on";

	var indenter:Indenter;
	var parsedCode:ParsedCode;

	public var lines(default, null):Array<CodeLine>;

	public function new(parsedCode:ParsedCode, indenter:Indenter) {
		lines = [];
		this.indenter = indenter;
		this.parsedCode = parsedCode;
		buildLines();
	}

	function buildLines() {
		var line:Null<CodeLine> = null;
		var index:Int = 0;
		while (index < parsedCode.tokenList.tokens.length) {
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
			if (line == null) {
				line = new CodeLine(indenter.calcIndent(tokenInfo.token) + tokenInfo.additionalIndent);
				lines.push(line);
			}
			line.addToken(tokenInfo, parsedCode.lineSeparator);
			if (tokenInfo.whitespaceAfter == Newline) {
				line = null;
			}
			index++;
		}
	}

	function skipFormatterOff(index:Int):Int {
		var startInfo:TokenInfo = parsedCode.tokenList.getTokenAt(index++);
		var startLine:Int = parsedCode.getLinePos(startInfo.token.pos.min).line;

		while (index < parsedCode.tokenList.tokens.length) {
			var tokenInfo:TokenInfo = parsedCode.tokenList.getTokenAt(index++);
			if (tokenInfo == null) {
				continue;
			}
			switch (tokenInfo.token.tok) {
				case CommentLine(FORMATTER_ON):
					var endLine:Int = parsedCode.getLinePos(tokenInfo.token.pos.max).line;
					copyVerbatim(startLine, endLine);
					return index;
				default:
			}
		}
		var endLine:Int = parsedCode.lines.length - 1;
		copyVerbatim(startLine, endLine);
		return index;
	}

	function copyVerbatim(startLine:Int, endLine:Int) {
		var startOffs:Int = parsedCode.linesIdx[startLine].l;
		var endOffs:Int = parsedCode.linesIdx[endLine].r;
		var content:String = parsedCode.getString(startOffs, endOffs);
		if (endLine < parsedCode.lines.length - 1) {
			content = content.rtrim();
		}
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
		return prefix + lines.map(function(line) return line.print(indenter, lineSeparator)).join(lineSeparator);
	}
}
