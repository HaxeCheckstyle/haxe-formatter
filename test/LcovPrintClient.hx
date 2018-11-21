import sys.io.FileOutput;
import mcover.coverage.CoverageReportClient;
import mcover.coverage.DataTypes;

class LcovPrintClient implements CoverageReportClient {
	public static inline var LCOV_INFO:String = "lcov.info";

	public var completionHandler(default, default):CoverageReportClient->Void;
	public var output(default, null):String;

	var testName:String;

	public function new(name:String) {
		testName = name;
	}

	public function report(coverage:Coverage) {
		sys.io.File.saveContent(LCOV_INFO, makeLine("TN", testName) + "\n");

		for (cls in coverage.getClasses()) {
			reportClass(cls);
		}
		if (completionHandler != null) {
			completionHandler(this);
		}
	}

	function reportClass(cls:Clazz) {
		var results:CoverageResult = cls.getResults();
		var c = cls.name.replace(".", "/") + ".hx";
		var text:StringBuf = new StringBuf();
		text.add(makeLine("SF", c));
		text.add(makeLine("FNF", '${results.m}'));
		text.add(makeLine("FNH", '${results.mc}'));
		text.add("\n");
		text.add(makeLine("BRF", '${results.b}'));
		text.add(makeLine("BRH", '${results.bt}'));
		text.add("\n");

		var lineCov:Map<Int, Int> = new Map<Int, Int>();
		var maxLineNumber:Int = 0;
		for (method in cls.getMethods()) {
			var max:Int = reportMethod(text, method, lineCov);
			if (max > maxLineNumber) {
				maxLineNumber = max;
			}
		}

		for (line in 0...maxLineNumber + 1) {
			if (!lineCov.exists(line)) {
				continue;
			}
			var count:Int = lineCov.get(line);
			text.add(makeLine("DA", '${line},${count}'));
		}

		text.add(makeLine("LF", '${results.l}'));
		text.add(makeLine("LH", '${results.lc}'));
		text.add("\n");

		text.add("end_of_record\n\n");
		appendCoverageFile(text.toString());
	}

	@:access(mcover.coverage.data.Method)
	function reportMethod(text:StringBuf, method:Method, lineCov:Map<Int, Int>):Int {
		var maxLineNumber:Int = 0;

		// TODO get first line number of method
		text.add(makeLine("FN", '1,${method.name}'));

		for (statementId in method.statementsById.keys()) {
			var statement:Statement = method.statementsById.get(statementId);
			for (line in statement.lines) {
				maxLineNumber = addLineCov(line, lineCov, statement.count, maxLineNumber);
			}
		}
		for (branchId in method.branchesById.keys()) {
			var branch:Branch = method.branchesById.get(branchId);
			if (branch.isCovered()) {
				for (line in branch.lines) {
					maxLineNumber = addLineCov(line, lineCov, 1, maxLineNumber);
				}
			} else {
				for (line in branch.lines) {
					text.add(makeLine("BRDA", '$line,${method.id},${branch.id},0'));
					maxLineNumber = addLineCov(line, lineCov, branch.totalCount, maxLineNumber);
				}
			}
		}
		return maxLineNumber;
	}

	function addLineCov(line:Int, lineCov:Map<Int, Int>, count:Int, maxLineNumber:Int):Int {
		if (line > maxLineNumber) {
			maxLineNumber = line;
		}
		if (!lineCov.exists(line)) {
			lineCov.set(line, count);
			return maxLineNumber;
		}
		var old:Int = lineCov.get(line);
		if (old > count) {
			lineCov.set(line, count);
		}
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
