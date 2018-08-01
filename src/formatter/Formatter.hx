package formatter;

import sys.FileSystem;
import haxe.CallStack;
import haxe.io.Path;
import formatter.config.Config;
import formatter.marker.MarkEmptyLines;
import formatter.marker.MarkLineEnds;
import formatter.marker.MarkTokenText;
import formatter.marker.MarkWhitespace;
import formatter.marker.Indenter;
import formatter.marker.MarkWrapping;
import formatter.marker.MarkSameLine;
import formatter.codedata.CodeLines;
import formatter.codedata.ParseFile;
import formatter.codedata.TokenData;

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
			if (config.isExcluded(file.name)) {
				return Disabled;
			}

			tokentree.TokenStream.MODE = RELAXED;
			var parsedCode = new ParsedCode(file, tokenData);

			var indenter = new Indenter(config.indentation);
			indenter.setParsedCode(parsedCode);

			MarkTokenText.markTokenText(parsedCode, indenter, config.indentation);
			MarkWhitespace.markWhitespace(parsedCode, config.whitespace);
			MarkLineEnds.markLineEnds(parsedCode, config.lineEnds);
			MarkSameLine.markSameLine(parsedCode, config.sameLine, config.whitespace);
			MarkWrapping.markWrapping(parsedCode, indenter, config);
			MarkEmptyLines.markEmptyLines(parsedCode, config.emptyLines);

			MarkTokenText.finalRun(parsedCode, indenter, config.indentation);

			var lines:CodeLines = new CodeLines(parsedCode, indenter);
			lines.applyWrapping(config.wrapping);
			MarkEmptyLines.finalRun(lines, config.emptyLines);

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
		var path:String = Path.directory(FileSystem.absolutePath(fileName));

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
