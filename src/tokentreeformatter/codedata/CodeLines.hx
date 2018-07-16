package tokentreeformatter.codedata;

import tokentreeformatter.config.WrapConfig;
import tokentreeformatter.marker.Indenter;

class CodeLines {
	var indenter:Indenter;

	public var lines(default, null):Array<CodeLine>;

	public function new(list:TokenList, indenter:Indenter) {
		lines = [];
		this.indenter = indenter;
		buildLines(list);
	}

	function buildLines(list:TokenList) {
		var line:CodeLine = null;
		for (tokenInfo in list.tokens) {
			if (tokenInfo == null) {
				continue;
			}
			if (line == null) {
				line = new CodeLine(indenter.calcIndent(tokenInfo.token));
				lines.push(line);
			}
			line.addToken(tokenInfo);
			if (tokenInfo.whitespaceAfter == Newline) {
				line = null;
			}
		}
	}

	public function applyWrapping(config:WrapConfig) {
		var wrappedLines:Array<CodeLine> = [];

		for (line in lines) {
			var wrappedCode:Array<CodeLine> = line.applyWrapping(config, indenter);
			wrappedLines = wrappedLines.concat(wrappedCode);
		}
		lines = wrappedLines;
	}

	public function print(lineSeparator:String):String {
		return lines.map(function(line) return line.print(indenter)).join(lineSeparator);
	}
}
