import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

class TestCaseMacro {
	#if macro
	public macro static function build(folder:String):Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
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
		var configExpr = {expr: EConst(CString(config)), pos: Context.currentPos()};
		var unformattedExpr = {expr: EConst(CString(unformatted)), pos: Context.currentPos()};
		var goldExpr = {expr: EConst(CString(gold)), pos: Context.currentPos()};
		var fieldName:String = new haxe.io.Path(fileName).file;
		var callExprDef = ECall(macro $i{"goldCheck"}, [unformattedExpr, goldExpr, configExpr]);
		var bodyExpr = {expr: callExprDef, pos: Context.currentPos()};
		var func = FFun({args: [], ret: null, expr: bodyExpr});
		return {
			kind: func, meta: [{name: "Test", pos: Context.currentPos()}], access: [APublic], name: fieldName, pos: Context.currentPos()
		};
	}

	static function collectAllFileNames(path:String):Array<String> {
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
	#end
}
