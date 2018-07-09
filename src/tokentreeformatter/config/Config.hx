package tokentreeformatter.config;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;

class Config {
	public var emptylines:EmptyLinesConfig;
	public var indentation:IndentationConfig;
	public var lineEnds:LineEndConfig;
	public var whitespace:WhitespaceConfig;
	public var wrapping:WrapConfig;

	public function new() {
		emptylines = {
			afterPackage: 1,
			afterImportsUsing: 1,
			betweenTypes: 1,
			anywhereInFileMax: 1,
			betweenClassStaticVars: 1,
			afterClassStaticVars: 1,
			afterClassPrivateVars: 1,
			betweenClassVars: 0,
			afterClassVars: 1,
			afterClassStaticFunctions: 1,
			betweenClassStaticFunctions: 0,
			afterClassPrivateFunctions: 1,
			betweenClassFunctions: 1
		};
		indentation = {
			conditionalPolicy: ALIGNED,
			character: "tab"
		};
		lineEnds = {
			at: AFTER,
			sharp: AFTER,
			leftCurly: AFTER,
			rightCurly: BOTH
		};
		whitespace = {
			pOpenPolicy: NONE_AFTER,
			pClosePolicy: NONE,
			bkOpenPolicy: NONE_AFTER,
			bkClosePolicy: NONE,
			brOpenPolicy: BEFORE,
			brClosePolicy: AROUND,
			typeParamOpenPolicy: NONE,
			typeParamClosePolicy: NONE,
			commaPolicy: AFTER,
			dotPolicy: NONE,
			semicolonPolicy: NONE,
			binopPolicy: AROUND,
			ifPolicy: AFTER,
			doPolicy: AFTER,
			whilePolicy: AFTER,
			forPolicy: AFTER,
			functionPolicy: AFTER,
			tryPolicy: AFTER,
			catchPolicy: AFTER
		};
		wrapping = {
			maxLineLength: 120,
			wrapAfterComma: true,
			wrapBeforeDot: true,
			wrapAfterBrOpen: true,
			wrapAfterBkOpen: true
		};
	}

	public function readConfig(fileName:String) {
		if (!FileSystem.exists(fileName)) {
			return;
		}
		parseConfig(Json.parse(File.getContent(fileName)));
	}

	function parseConfig(config:FormatterConfig) {
		if (config.emptylines != null) {
			for (field in Reflect.fields(config.emptylines)) {
				Reflect.setField(emptylines, field, Reflect.field(config.emptylines, field));
			}
		}
		if (config.indentation != null) {
			for (field in Reflect.fields(config.indentation)) {
				Reflect.setField(indentation, field, Reflect.field(config.indentation, field));
			}
		}
		if (config.lineEnds != null) {
			for (field in Reflect.fields(config.lineEnds)) {
				Reflect.setField(lineEnds, field, Reflect.field(config.lineEnds, field));
			}
		}
		if (config.whitespace != null) {
			for (field in Reflect.fields(config.whitespace)) {
				Reflect.setField(whitespace, field, Reflect.field(config.whitespace, field));
			}
		}
		if (config.wrapping != null) {
			for (field in Reflect.fields(config.wrapping)) {
				Reflect.setField(wrapping, field, Reflect.field(config.wrapping, field));
			}
		}
	}
}