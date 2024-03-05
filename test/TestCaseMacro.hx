import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Type.ClassType;
import sys.FileSystem;
import sys.io.File;

using haxe.macro.ExprTools;

class TestCaseMacro {
	#if macro
	public macro static function build(folder:String):Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		var cls:ClassType = Context.getLocalClass().get();
		if (!shouldApply(cls, ":testcases")) {
			return fields;
		}
		cls.meta.add(":testcases", [], cls.pos);

		// revert the effects of implementing ITest interface
		//
		// unfortunately utest initialises before this macro runs, making our testcases invisible to utest.
		// additionally test-adapter needs ITest interface to be able to collect position info of testcases
		// which means we have to implement utests ITest interface to keep test explorer working.
		//
		// solution:
		// we remove the field and meta info added by @:autoBuild (through ITest), add our testcases and
		// then re-apply utest's test builder macro a second time
		fields = fields.filter(f -> f.name != "__initializeUtest__");
		cls.meta.remove(":utestProcessed");

		var testCases:Array<String> = collectAllFileNames(folder);
		var singleRun:TestSingleRun = new TestSingleRun();
		for (testCase in testCases) {
			if (!singleRun.matchesTest(testCase)) {
				continue;
			}
			var field:Field = buildTestCaseField(testCase);
			if (field == null) {
				continue;
			}
			fields.push(field);
		}
		return fields;
	}

	public static function shouldApply(cls:ClassType, what:String):Bool {
		if (cls.meta.has(what)) {
			return false;
		}

		if (cls.superClass == null) {
			return true;
		}
		return shouldApply(cls.superClass.t.get(), what);
	}

	static function buildTestCaseField(fileName:String):Field {
		var content:String = sys.io.File.getContent(fileName);
		var nl = "\r?\n";
		var reg = new EReg('$nl$nl---$nl$nl', "g");
		var segments = reg.split(content);
		if (segments.length != 3) {
			throw 'invalid testcase format for: $fileName';
		}
		var config:String = segments[0];
		var unformatted:String = segments[1];
		var gold:String = segments[2];
		var fieldName:String = new haxe.io.Path(fileName).file;
		fieldName = 'test_$fieldName';
		var lineSeparator:String = detectLineSeparator(content);

		var field = (macro class {
			public function $fieldName() {
				goldCheck($v{fileName}, $v{unformatted}, $v{gold}, $v{lineSeparator}, $v{config});
			};
		}).fields[0];

		// make assertion failures show up in testfile
		field.pos = PositionTools.make({file: fileName, min: content.length, max: content.length});
		switch (field.kind) {
			case FFun(f):
				relocateExpr(f.expr, field.pos);
			default:
		}

		return field;
	}

	static function relocateExpr(expr:Expr, pos:Position):Expr {
		expr.pos = pos;
		return expr.map((e) -> relocateExpr(e, pos));
	}

	static function collectAllFileNames(path:String):Array<String> {
		#if display
		return [];
		#end
		var items:Array<String> = FileSystem.readDirectory(path);
		var files:Array<String> = [];
		for (item in items) {
			if (item == "." || item == "..") {
				continue;
			}
			var fileName = Path.join([path, item]);
			if (FileSystem.isDirectory(fileName)) {
				files = files.concat(collectAllFileNames(fileName));
				continue;
			}
			if (!item.endsWith(".hxtest")) {
				continue;
			}
			files.push(Path.join([path, item]));
		}
		return files;
	}

	public static function detectLineSeparator(code:String):String {
		for (i in 0...code.length) {
			var char = code.charAt(i);
			if ((char == "\r") || (char == "\n")) {
				var separator:String = char;
				if ((char == "\r") && (i + 1 < code.length)) {
					char = code.charAt(i + 1);
					if (char == "\n") {
						separator += char;
					}
				}
				return separator;
			}
		}

		// default
		return "\n";
	}
	#end
}
