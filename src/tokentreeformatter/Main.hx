package tokentreeformatter;

import tokentreeformatter.config.Config;
import tokentreeformatter.printer.IPrinter;
import tokentreeformatter.printer.StdPrinter;
import tokentreeformatter.marker.MarkEmptyLines;
import tokentreeformatter.marker.MarkLineEnds;
import tokentreeformatter.marker.MarkTokenText;
import tokentreeformatter.marker.MarkWhitespace;
import tokentreeformatter.marker.Indenter;
import tokentreeformatter.marker.MarkWrapping;

import tokentreeformatter.codedata.CodeLines;

class Main {
	public function new() {}

	public function formatFile(fileName:String) {
		try {
			tokentree.TokenStream.MODE = RELAXED;
			var config:Config = new Config();
			var indenter:Indenter = new Indenter(config.indentation);
			var printer:IPrinter = new StdPrinter();

			var parsedCode:ParsedCode = ParsedCode.createFromFile(fileName);
			indenter.setParsedCode(parsedCode);

			MarkTokenText.markTokenText(parsedCode, indenter);
			MarkEmptyLines.markEmptyLines(parsedCode, config.emptylines);
			MarkWhitespace.markWhitespace(parsedCode, config.whitespace);
			MarkLineEnds.markLineEnds(parsedCode, config.lineEnds);
			MarkWrapping.markWrapping(parsedCode, config.wrapping);

			var lines:CodeLines = new CodeLines(parsedCode.tokenList, indenter);
			lines.applyWrapping(config.wrapping);
			MarkEmptyLines.finalRun(lines, config.emptylines);

			lines.print(printer);
		}
		catch (e:Any) {
			Sys.println('unhandled exception caught: $e');
		}
	}

	public static function main() {
		var args:Array<String> = Sys.args();

		var main:Main = new Main();
		for (arg in args) {
			main.formatFile(arg);
		}
	}
}