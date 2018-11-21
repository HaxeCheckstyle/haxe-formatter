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
		text.add("\n");

		var lineCov:Map<Int, Int> = new Map<Int, Int>();
		var branchCov:Map<Int, String> = new Map<Int, String>();
		var maxLineNumber:Int = 0;

		var num:Int = 0;
		for (method in cls.getMethods()) {
			// TODO get first line number of method
			text.add(makeLine("FN", '${num++},${method.name}'));
		}
		text.add("\n");

		for (method in cls.getMethods()) {
			var methodResults:CoverageResult = method.getResults();
			text.add(makeLine("FNDA", '${methodResults.m},${method.name}'));
		}
		text.add("\n");
		text.add(makeLine("FNF", '${results.m}'));
		text.add(makeLine("FNH", '${results.mc}'));
		text.add("\n");

		maxLineNumber = 0;
		for (method in cls.getMethods()) {
			var max:Int = reportBranches(text, method, branchCov);
			if (max > maxLineNumber) {
				maxLineNumber = max;
			}
		}
		for (line in 0...maxLineNumber + 1) {
			if (!branchCov.exists(line)) {
				continue;
			}
			var count:String = branchCov.get(line);
			text.add(makeLine("BRDA", '${line},${count}'));
		}

		text.add("\n");
		text.add(makeLine("BRF", '${results.b}'));
		text.add(makeLine("BRH", '${results.bt}'));
		text.add("\n");

		maxLineNumber = 0;
		for (method in cls.getMethods()) {
			var max:Int = reportStatements(text, method, lineCov);
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
		text.add("\n");

		text.add(makeLine("LF", '${results.l}'));
		text.add(makeLine("LH", '${results.lc}'));
		text.add("\n");

		text.add("end_of_record\n\n");
		appendCoverageFile(text.toString());
	}

	@:access(mcover.coverage.data.Method)
	function reportStatements(text:StringBuf, method:Method, lineCov:Map<Int, Int>):Int {
		var maxLineNumber:Int = 0;

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
					maxLineNumber = addLineCov(line, lineCov, branch.totalCount, maxLineNumber);
				}
			}
		}
		return maxLineNumber;
	}

	@:access(mcover.coverage.data.Method)
	function reportBranches(text:StringBuf, method:Method, branchCov:Map<Int, String>):Int {
		var maxLineNumber:Int = 0;

		for (branchId in method.branchesById.keys()) {
			var branch:Branch = method.branchesById.get(branchId);
			var data:String = '${method.id},${branch.id},${branch.totalCount}';
			if (branch.isCovered()) {
				for (line in branch.lines) {
					maxLineNumber = addLineCov(line, branchCov, data, maxLineNumber);
				}
			} else {
				for (line in branch.lines) {
					if (branch.isPartiallyCovered()) {
						data = '${method.id},${branch.id},-';
					}
					maxLineNumber = addLineCov(line, branchCov, data, maxLineNumber);
				}
			}
		}
		return maxLineNumber;
	}

	function addLineCov<T>(line:Int, lineCov:Map<Int, T>, count:T, maxLineNumber:Int):Int {
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
