import haxe.EntryPoint;
import haxe.Json;
import sys.io.File;
import sys.io.FileOutput;
import massive.munit.TestRunner;
import mcover.coverage.munit.client.MCoverPrintClient;
import mcover.coverage.data.CoverageResult;
import mcover.coverage.data.Statement;
import mcover.coverage.data.Branch;
import mcover.coverage.MCoverage;

class TestMain {
	public function new() {
		var suites:Array<Class<massive.munit.TestSuite>> = [TestSuite];
		var client:MCoverPrintClient = new MCoverPrintClient();
		// MCoverage.getLogger().addClient(new LcovPrintClient("Formatter Unittests"));
		MCoverage.getLogger().addClient(new CodecovJsonPrintClient());

		#if detailed_coverage
		client.includeClassAndPackageBreakdowns = true;
		client.includeMissingBlocks = true;
		#end
		var runner:TestRunner = new TestRunner(client);
		runner.completionHandler = completionHandler;
		#if (neko || cpp || hl)
		EntryPoint.addThread(function() {
			while (true) {
				Sys.sleep(1.0);
			}
		});
		#end
		runner.run(suites);
		EntryPoint.run();
		#if eval
		// setupCoverageReport();
		#end
	}

	function completionHandler(success:Bool) {
		// setupCoverageReport();
		if (success) {
			File.saveContent("test/formatter-result.txt", "\n---\n");
		}
		#if eval
		if (!success) {
			Sys.exit(1);
		}
		#else
		Sys.exit(success ? 0 : 1);
		#end
	}

	// function setupCoverageReport() {
	// 	var report = {coverage: {}};
	// 	var classes = MCoverage.getLogger().coverage.getClasses();
	// 	for (cls in classes) {
	// 		var coverageData:Array<LineCoverageResult> = [null];
	// 		var results:CoverageResult = cls.getResults();
	// 		trace(cls.name + " " + results);
	// 		for (i in 1...results.l) {
	// 			coverageData[i] = null;
	// 		}
	// 		var c = cls.name.replace(".", "/") + ".hx";
	// 		var missingStatements:Array<Statement> = cls.getMissingStatements();
	// 		// trace(missingStatements);
	// 		var maxLine:Int = results.l;
	// 		for (stmt in missingStatements) {
	// 			// trace(stmt.name + " " + stmt.lines);
	// 			for (line in stmt.lines) {
	// 				if (line > maxLine) {
	// 					maxLine = line;
	// 				}
	// 				coverageData[line] = 0;
	// 			}
	// 		}
	// 		var missingBranches:Array<Branch> = cls.getMissingBranches();
	// 		for (branch in missingBranches) {
	// 			// trace(branch.name + " " + branch.lines);
	// 			for (line in branch.lines) {
	// 				if (line > maxLine) {
	// 					maxLine = line;
	// 				}
	// 				// if (branch.lines.length <= 0) {
	// 				// 	continue;
	// 				// }
	// 				var count:Int = 0;
	// 				if (branch.trueCount > 0) {
	// 					count++;
	// 				}
	// 				if (branch.falseCount > 0) {
	// 					count++;
	// 				}
	// 				// var line:Int = branch.lines[branch.lines.length - 1];
	// 				coverageData[line] = count + "/2";
	// 			}
	// 		}
	// 		trace(cls.name + " " + results.l + " " + maxLine);
	// 		Reflect.setField(report.coverage, c, coverageData);
	// 	}
	// 	var file:FileOutput = File.write("coverage.json");
	// 	file.writeString(Json.stringify(report));
	// 	file.close();
	// }
	static function main() {
		new TestMain();
	}
}

typedef LineCoverageResult = Dynamic;
