package formatter;

import sys.io.File;
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
import formatter.codedata.FormatterInputData;
import formatter.codedata.ParseFile;
import formatter.codedata.TokenData;
import tokentree.TokenTreeBuilder.TokenTreeEntryPoint;

enum Result {
	Success(formattedCode:String);
	Failure(errorMessage:String);
	Disabled;
}

class Formatter {
	static inline var FORMATTER_JSON:String = "hxformat.json";

	public function new() {}

	public function formatInput(input:FormatterInput, config:Config):Result {
		var inputData:FormatterInputData;
		switch (input) {
			case FileInput(fileName, config, lineSeparator, entryPoint):
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
			case Code(code, fileName, config, lineSeparator, entryPoint):
				var content:Bytes = Bytes.ofString(code);
				inputData = {
					fileName: fileName,
					content: content,
					config: config,
					lineSeparator: lineSeparator,
					entryPoint: entryPoint
				};
				return formatInputData(inputData);
			case CodeBytes(code, fileName, config, lineSeparator, entryPoint):
				inputData = {
					fileName: fileName,
					content: code,
					config: config,
					lineSeparator: lineSeparator,
					entryPoint: entryPoint
				};
				return formatInputData(inputData);
			case Tokens(tokenList, tokenTree, code, fileName, config, lineSeparator, entryPoint):
				var content:Bytes = Bytes.ofString(code);
				inputData = {
					fileName: fileName,
					content: content,
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

	public function formatFile(file:ParseFile, ?tokenData:TokenData):Result {
		try {
			var config:Config = loadConfig(file.name);

			var inputData:FormatterInputData = {
				fileName: file.name,
				content: file.content,
				config: config,
				lineSeparator: file.lineSeparator,
				entryPoint: TYPE_LEVEL
			};
			if (tokenData != null) {
				inputData.tokenList = tokenData.tokens;
				inputData.tokenTree = tokenData.tokenTree;
			}
			return formatInputData(inputData);
		} catch (e:Any) {
			#if debug
			var callstack = CallStack.toString(CallStack.exceptionStack());
			return Failure(e + "\n" + callstack + "\n\n");
			#else
			return Failure(e);
			#end
		}
	}

	public function loadConfigFromFileLocation(fileName:String):Null<Config> {
		var configFileName:Null<String> = determineFormatterConfig(fileName);
		if (configFileName == null) {
			return null;
		}
		var config:Config = new Config();
		config.readConfig(configFileName);
		return config;
	}

	function formatInputData(inputData:FormatterInputData):Result {
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
		var config:Null<Config> = loadConfigFromFileLocation(fileName);
		if (config == null) {
			return new Config();
		}
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

enum FormatterInput {
	FileInput(fileName:String, config:Config, ?lineSeparator:String, ?entryPoint:TokenTreeEntryPoint);
	Code(code:String, fileName:String, config:Config, ?lineSeparator:String, ?entryPoint:TokenTreeEntryPoint);
	CodeBytes(code:Bytes, fileName:String, config:Config, ?lineSeparator:String, ?entryPoint:TokenTreeEntryPoint);
	Tokens(tokenList:Array<Token>, tokenTree:TokenTree, code:String, fileName:String, config:Config, ?lineSeparator:String, ?entryPoint:TokenTreeEntryPoint);
}
