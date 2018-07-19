package tokentreeformatter;

import haxe.CallStack;
import haxe.io.Path;
import tokentreeformatter.config.Config;
import tokentreeformatter.marker.MarkEmptyLines;
import tokentreeformatter.marker.MarkLineEnds;
import tokentreeformatter.marker.MarkTokenText;
import tokentreeformatter.marker.MarkWhitespace;
import tokentreeformatter.marker.Indenter;
import tokentreeformatter.marker.MarkWrapping;
import tokentreeformatter.marker.MarkSameLine;
import tokentreeformatter.codedata.CodeLines;
import tokentreeformatter.codedata.ParseFile;
import tokentreeformatter.codedata.TokenData;

enum Result {
	Success(formattedCode:String);
	Failure(errorMessage:String);
	Disabled;
}

class Formatter {
	static inline var FORMATTER_JSON:String = "hxformat.json";

	public function new() {}

	public function formatFile(file:ParseFile, ?tokenData:TokenData):Result {
		try {
			var config:Config = loadConfig(file.name);
			if (config.disableFormatting) {
				return Disabled;
			}

			tokentree.TokenStream.MODE = RELAXED;
			var parsedCode = new ParsedCode(file, tokenData);

			var indenter = new Indenter(config.indentation);
			indenter.setParsedCode(parsedCode);

			MarkEmptyLines.markEmptyLines(parsedCode, config.emptyLines);
			MarkWhitespace.markWhitespace(parsedCode, config.whitespace);
			MarkLineEnds.markLineEnds(parsedCode, config.lineEnds);
			MarkTokenText.markTokenText(parsedCode, indenter);
			MarkWrapping.markWrapping(parsedCode, config.wrapping);
			MarkSameLine.markSameLine(parsedCode, config.sameLine, config.whitespace);

			var lines:CodeLines = new CodeLines(parsedCode, indenter);
			lines.applyWrapping(config.wrapping);
			MarkEmptyLines.finalRun(lines, config.emptyLines);
			indenter.finalRun(lines);

			return Success(lines.print(parsedCode.lineSeparator));
		} catch (e:Any) {
			var callstack = CallStack.toString(CallStack.exceptionStack());
			return Failure(e + "\n" + callstack + "\n\n");
		}
	}

	function loadConfig(fileName:String):Config {
		var config:Config = new Config();
		var configFileName:String = determineFormatterConfig(fileName);
		if (configFileName == null) {
			return config;
		}
		config.readConfig(configFileName);
		return config;
	}

	function determineFormatterConfig(fileName:String):Null<String> {
		var path:String = Path.directory(fileName);

		while (path.length > 0) {
			var configFile:String = Path.join([path, FORMATTER_JSON]);
			if (sys.FileSystem.exists(configFile)) {
				return configFile;
			}
			path = Path.normalize(Path.join([path, ".."]));
		}
		return null;
	}
}
