import haxe.Json;
import sys.io.FileOutput;
import mcover.coverage.CoverageReportClient;
import mcover.coverage.DataTypes;

class CodecovJsonPrintClient implements CoverageReportClient {
	public static inline var LCOV_INFO:String = "lcov.info";

	public var completionHandler(default, default):CoverageReportClient->Void;
	public var output(default, null):String;

	public function new() {}

	public function report(coverage:Coverage) {
		var covReport = {coverage: {}};

		var text:StringBuf = new StringBuf();
		text.add("{\n\t\"coverage\": {\n");

		var first:Bool = true;
		for (cls in coverage.getClasses()) {
			if (!first) {
				text.add(",\n");
			}
			text.add(reportClass(cls));
			first = false;
		}
		text.add("\n\t}\n}\n");

		var file:FileOutput = sys.io.File.write("coverage.json");
		file.writeString(text.toString());
		file.close();

		if (completionHandler != null) {
			completionHandler(this);
		}
	}

	function reportClass(cls:Clazz):String {
		var c = cls.name.replace(".", "/") + ".hx";
		var text:StringBuf = new StringBuf();
		text.add('\t\t"$c": {\n');

		var lineCov:Map<Int, String> = new Map<Int, String>();
		var maxLineNumber:Int = 0;
		for (method in cls.getMethods()) {
			var max:Int = reportMethod(text, method, lineCov);
			if (max > maxLineNumber) {
				maxLineNumber = max;
			}
		}
		var first:Bool = true;
		for (line in 0...maxLineNumber + 1) {
			if (!lineCov.exists(line)) {
				continue;
			}
			if (!first) {
				text.add(",\n");
			}
			first = false;
			var count = lineCov.get(line);
			text.add('\t\t\t"$line": $count');
		}
		text.add("\n\t\t}");
		return text.toString();
	}

	@:access(mcover.coverage.data.Method)
	function reportMethod(text:StringBuf, method:Method, lineCov:Map<Int, String>):Int {
		var maxLineNumber:Int = 0;

		for (statementId in method.statementsById.keys()) {
			var statement:Statement = method.statementsById.get(statementId);
			for (line in statement.lines) {
				maxLineNumber = addLineCov(line, lineCov, '${statement.count}', maxLineNumber);
			}
		}
		for (branchId in method.branchesById.keys()) {
			var branch:Branch = method.branchesById.get(branchId);
			if (branch.isCovered()) {
				for (line in branch.lines) {
					maxLineNumber = addLineCov(line, lineCov, "1", maxLineNumber);
				}
			} else {
				for (line in branch.lines) {
					maxLineNumber = addLineCov(line, lineCov, "\"1/2\"", maxLineNumber);
				}
			}
		}
		return maxLineNumber;
	}

	function addLineCov(line:Int, lineCov:Map<Int, String>, count:String, maxLineNumber:Int):Int {
		if (line > maxLineNumber) {
			maxLineNumber = line;
		}
		lineCov.set(line, count);
		return maxLineNumber;
	}

	function appendCoverageFile(text:String) {
		var file:FileOutput = sys.io.File.append(LCOV_INFO);
		file.writeString(text.toString());
		file.close();
	}

	inline function makeLine(key:String, value:String):String {
		return '$key:$value\n';
	}
}
