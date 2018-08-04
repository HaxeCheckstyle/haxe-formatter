package formatter.codedata;

import formatter.config.WrapConfig;
import formatter.marker.Indenter;

class CodeLines {
	static inline var formatterOff:String = " @formatter:off";
	static inline var formatterOn:String = " @formatter:on";

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
		var line:CodeLine = null;
		var index:Int = 0;
		while (index < parsedCode.tokenList.tokens.length) {
			var tokenInfo:TokenInfo = parsedCode.tokenList.getTokenAt(index);
			if (tokenInfo == null) {
				index++;
				continue;
			}
			switch (tokenInfo.token.tok) {
				case CommentLine(formatterOff):
					line = null;
					index = skipFormatterOff(parsedCode, index);
					continue;
				default:
			}
			if (line == null) {
				line = new CodeLine(indenter.calcIndent(tokenInfo.token));
				lines.push(line);
			}
			line.addToken(tokenInfo);
			if (tokenInfo.whitespaceAfter == Newline) {
				line = null;
			}
			index++;
		}
	}

	function skipFormatterOff(parsedCode:ParsedCode, index:Int):Int {
		var startInfo:TokenInfo = parsedCode.tokenList.getTokenAt(index++);
		var startLine:Int = parsedCode.getLinePos(startInfo.token.pos.min).line;

		while (index < parsedCode.tokenList.tokens.length) {
			var tokenInfo:TokenInfo = parsedCode.tokenList.getTokenAt(index++);
			if (tokenInfo == null) {
				continue;
			}
			switch (tokenInfo.token.tok) {
				case CommentLine(formatterOn):
					var endLine:Int = parsedCode.getLinePos(tokenInfo.token.pos.max).line;
					copyVerbatim(parsedCode, startLine, endLine);
					return index;
				default:
			}
		}
		var endLine:Int = parsedCode.lines.length - 1;
		copyVerbatim(parsedCode, startLine, endLine);
		return index;
	}

	function copyVerbatim(parsedCode:ParsedCode, startLine:Int, endLine:Int) {
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
		return lines.map(function(line) return line.print(indenter, lineSeparator)).join(lineSeparator);
	}
}
