package tokentreeformatter.config;

import haxe.CallStack;
import sys.FileSystem;
import sys.io.File;
import json2object.JsonParser;

class Config {
	public var emptyLines:EmptyLinesConfig;
	public var indentation:IndentationConfig;
	public var lineEnds:LineEndConfig;
	public var sameLine:SameLineConfig;
	public var whitespace:WhitespaceConfig;
	public var wrapping:WrapConfig;
	public var disableFormatting:Bool;

	public function new() {
		readConfigFromString("{}", "hxformat.json");
	}

	public function readConfig(fileName:String) {
		if (!FileSystem.exists(fileName)) {
			return;
		}
		readConfigFromString(File.getContent(fileName), fileName);
	}

	public function readConfigFromString(jsonContent:String, fileName:String) {
		try {
			var parser:JsonParser<FormatterConfig> = new JsonParser<FormatterConfig>();
			var data:FormatterConfig = parser.fromJson(jsonContent, fileName);
			emptyLines = data.emptyLines;
			indentation = data.indentation;
			lineEnds = data.lineEnds;
			sameLine = data.sameLine;
			whitespace = data.whitespace;
			wrapping = data.wrapping;
			disableFormatting = data.disableFormatting;
		} catch (e:Any) {
			// disable formatting rather than using an incorrect format
			disableFormatting = true;
			trace(e);
			Sys.println(CallStack.toString(CallStack.callStack()));
		}
	}
}
