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
import formatter.marker.wrapping.MarkWrapping;
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
			return formatFileWithConfig(file, config, tokenData);
		} catch (e:Any) {
			#if debug
			var callstack = CallStack.toString(CallStack.exceptionStack());
			return Failure(e + "\n" + callstack + "\n\n");
			#else
			return Failure(e);
			#end
		}
	}

	public function formatFileWithConfig(file:ParseFile, config:Config, ?tokenData:TokenData):Result {
		try {
			if (config.disableFormatting) {
				return Disabled;
			}
			if (config.isExcluded(file.name)) {
				return Disabled;
			}

			tokentree.TokenStream.MODE = RELAXED;
			var parsedCode = new ParsedCode(file, tokenData);
			FormatStats.addOrigLines(parsedCode.lines.length);

			var indenter = new Indenter(config.indentation);
			indenter.setParsedCode(parsedCode);

			var markTokenText:MarkTokenText = new MarkTokenText(config, parsedCode, indenter);
			var markWhitespace:MarkWhitespace = new MarkWhitespace(config, parsedCode, indenter);
			var markLineEnds:MarkLineEnds = new MarkLineEnds(config, parsedCode, indenter);
			var markSameLine:MarkSameLine = new MarkSameLine(config, parsedCode, indenter);
			var markWrapping:MarkWrapping = new MarkWrapping(config, parsedCode, indenter);
			var markEmptyLines:MarkEmptyLines = new MarkEmptyLines(config, parsedCode, indenter);

			markTokenText.run();
			markWhitespace.run();
			markLineEnds.run();
			markSameLine.run();
			markWrapping.run();
			markEmptyLines.run();

			markTokenText.finalRun();

			var lines:CodeLines = new CodeLines(parsedCode, indenter);
			lines.applyWrapping(config.wrapping);
			markEmptyLines.finalRun(lines);

			var formatted:String = lines.print(parsedCode.lineSeparator);
			FormatStats.addFormattedLines(formatted.split(parsedCode.lineSeparator).length);
			return Success(formatted);
		} catch (e:Any) {
			var callstack = CallStack.toString(CallStack.exceptionStack());
			return Failure(e + "\n" + callstack + "\n\n");
		}
	}

	function loadConfig(fileName:String):Config {
		var config:Config = new Config();
		var configFileName:Null<String> = determineFormatterConfig(fileName);
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
