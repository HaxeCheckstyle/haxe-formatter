package tokentreeformatter.config;

import sys.FileSystem;
import sys.io.File;
import json2object.JsonParser;

class Config {
	public var emptylines:EmptyLinesConfig;
	public var indentation:IndentationConfig;
	public var lineEnds:LineEndConfig;
	public var whitespace:WhitespaceConfig;
	public var wrapping:WrapConfig;

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
		var parser:JsonParser<FormatterConfig> = new JsonParser<FormatterConfig>();
		var data:FormatterConfig = parser.fromJson(jsonContent, fileName);
		emptylines = data.emptylines;
		indentation = data.indentation;
		lineEnds = data.lineEnds;
		whitespace = data.whitespace;
		wrapping = data.wrapping;
	}
}