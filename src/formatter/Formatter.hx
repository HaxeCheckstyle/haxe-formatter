package formatter;

#if sys
import sys.io.File;
import sys.FileSystem;
#end
import haxe.CallStack;
import haxe.io.Path;
import formatter.config.Config;
import formatter.marker.MarkAdditionalIndentation;
import formatter.marker.MarkEmptyLines;
import formatter.marker.MarkLineEnds;
import formatter.marker.MarkTokenText;
import formatter.marker.MarkWhitespace;
import formatter.marker.Indenter;
import formatter.marker.wrapping.MarkWrapping;
import formatter.marker.MarkSameLine;
import formatter.codedata.CodeLines;
import formatter.codedata.FormatterInputData;
import tokentree.TokenTreeBuilder.TokenTreeEntryPoint;

enum Result {
	Success(formattedCode:String);
	Failure(errorMessage:String);
	Disabled;
}

class Formatter {
	static inline var FORMATTER_JSON:String = "hxformat.json";

	public static function format(input:FormatterInput, ?config:Config, ?lineSeparator:String, ?entryPoint:TokenTreeEntryPoint):Result {
		if (config == null) {
			config = new Config();
		}
		var inputData:FormatterInputData;
		switch (input) {
			#if sys
			case FileInput(fileName):
				if (!FileSystem.exists(fileName)) {
					Sys.println('Skipping \'$fileName\' (path does not exist)');
					return Failure('File "$fileName" not found');
				}
				var content:Bytes = File.getBytes(fileName);
				inputData = {
					fileName: fileName,
					content: content,
					config: config,
					lineSeparator: lineSeparator,
					entryPoint: entryPoint
				};
				return formatInputData(inputData);
			#end
			case Code(code):
				var content:Bytes = Bytes.ofString(code);
				inputData = {
					fileName: "code snippet",
					content: content,
					config: config,
					lineSeparator: lineSeparator,
					entryPoint: entryPoint
				};
				return formatInputData(inputData);
			case Tokens(tokenList, tokenTree, code):
				inputData = {
					fileName: "<unknown.hx>",
					content: code,
					tokenList: tokenList,
					tokenTree: tokenTree,
					config: config,
					lineSeparator: lineSeparator,
					entryPoint: entryPoint
				};
				return formatInputData(inputData);
		}
		return Failure("implement me");
	}

#if sys
	/**
		Determines the config to be used for a particular `path` (either a directory or a file),
		based on the `hxformat.json` that is closest to it.

		If there is no `hxformat.json`, `null` is returned.
	**/
	public static function loadConfig(path:String):Null<Config> {
		var configFileName:Null<String> = determineConfig(path);
		if (configFileName == null) {
			return null;
		}
		var config = new Config();
		config.readConfig(configFileName);
		return config;
	}
#end

	static function formatInputData(inputData:FormatterInputData):Result {
		try {
			var config:Config = inputData.config;
			if (config.disableFormatting) {
				return Disabled;
			}
			if (config.isExcluded(inputData.fileName)) {
				return Disabled;
			}

			tokentree.TokenStream.MODE = RELAXED;
			var parsedCode = new ParsedCode(inputData);
			FormatStats.addOrigLines(parsedCode.lines.length);

			var indenter = new Indenter(config.indentation);
			indenter.setParsedCode(parsedCode);

			var markTokenText = new MarkTokenText(config, parsedCode, indenter);
			var markWhitespace = new MarkWhitespace(config, parsedCode, indenter);
			var markLineEnds = new MarkLineEnds(config, parsedCode, indenter);
			var markSameLine = new MarkSameLine(config, parsedCode, indenter);
			var markWrapping = new MarkWrapping(config, parsedCode, indenter);
			var markEmptyLines = new MarkEmptyLines(config, parsedCode, indenter);
			var markAdditionalIndent = new MarkAdditionalIndentation(config, parsedCode, indenter);

			markTokenText.run();
			markWhitespace.run();
			markLineEnds.run();
			markSameLine.run();
			markWrapping.run();
			markEmptyLines.run();

			markTokenText.finalRun();
			markAdditionalIndent.run();

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

#if sys
	static function determineConfig(fileName:String):Null<String> {
		var path:String = FileSystem.absolutePath(fileName);
		if (!FileSystem.isDirectory(path)) {
			path = Path.directory(path);
		}
		while (path.length > 0) {
			var configFile:String = Path.join([path, FORMATTER_JSON]);
			if (sys.FileSystem.exists(configFile)) {
				return configFile;
			}
			path = Path.normalize(Path.join([path, ".."]));
		}
		return null;
	}
#end
}

enum FormatterInput {
#if sys
	FileInput(fileName:String);
#end
	Code(code:String);
	Tokens(tokenList:Array<Token>, tokenTree:TokenTree, code:Bytes);
}
