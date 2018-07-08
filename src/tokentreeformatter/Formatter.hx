package tokentreeformatter;

import tokentreeformatter.config.Config;
import tokentreeformatter.marker.MarkEmptyLines;
import tokentreeformatter.marker.MarkLineEnds;
import tokentreeformatter.marker.MarkTokenText;
import tokentreeformatter.marker.MarkWhitespace;
import tokentreeformatter.marker.Indenter;
import tokentreeformatter.marker.MarkWrapping;
import tokentreeformatter.codedata.CodeLines;
import tokentreeformatter.codedata.ParseFile;
import sys.io.File;

class Formatter {
	public function new() {}

	public function formatFile(file:ParseFile, config:Config):String {
		try {
			tokentree.TokenStream.MODE = RELAXED;
			var indenter = new Indenter(config.indentation);

			var parsedCode = ParsedCode.createFromByteData(file);
			indenter.setParsedCode(parsedCode);

			MarkTokenText.markTokenText(parsedCode, indenter);
			MarkEmptyLines.markEmptyLines(parsedCode, config.emptylines);
			MarkWhitespace.markWhitespace(parsedCode, config.whitespace);
			MarkLineEnds.markLineEnds(parsedCode, config.lineEnds);
			MarkWrapping.markWrapping(parsedCode, config.wrapping);

			var lines:CodeLines = new CodeLines(parsedCode.tokenList, indenter);
			lines.applyWrapping(config.wrapping);
			MarkEmptyLines.finalRun(lines, config.emptylines);

			return lines.print();
		}
		catch (e:Any) {
			Sys.println('unhandled exception caught: $e');
			return null;
		}
	}

	public static function main() {
		var args:Array<String> = Sys.args();

		var formatter = new Formatter();
		for (arg in args) {
			formatter.formatFile({name: arg, content: cast File.getBytes(arg)}, new Config());
		}
	}
}