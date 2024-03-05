import sys.io.File;
import formatter.EmptyLinesTest;
import formatter.FormatStatsTest;
import formatter.codedata.TokenListTest;
import testcases.EmptyLinesTestCases;
import testcases.ExpressionLevelTestCases;
import testcases.FormatRangeTestCases;
import testcases.IndentationTestCases;
import testcases.LineEndsTestCases;
import testcases.MissingTestCases;
import testcases.Other;
import testcases.SameLineTestCases;
import testcases.WhitespaceTestCases;
import testcases.WrappingTestCases;
import utest.Runner;
import utest.ui.text.DiagnosticsReport;

class TestMain {
	public function new() {
		var tests:Array<() -> ITest> = [];

		var singleRun:TestSingleRun = new TestSingleRun();
		if (!singleRun.isSingleRun()) {
			tests.push(SelfTest.new);
			tests.push(FormatStatsTest.new);
			tests.push(TokenListTest.new);
			tests.push(EmptyLinesTest.new);
		}

		tests.push(cast EmptyLinesTestCases.new);
		tests.push(cast ExpressionLevelTestCases.new);
		tests.push(cast FormatRangeTestCases.new);
		tests.push(cast IndentationTestCases.new);
		tests.push(cast LineEndsTestCases.new);
		tests.push(cast MissingTestCases.new);
		tests.push(cast Other.new);
		tests.push(cast SameLineTestCases.new);
		tests.push(cast WhitespaceTestCases.new);
		tests.push(cast WrappingTestCases.new);

		var runner:Runner = new Runner();

		var failed = false;
		runner.onProgress.add(r -> {
			if (!r.result.allOk()) {
				failed = true;
			}
		});
		runner.onComplete.add(_ -> {
			completionHandler(!failed);
		});

		new DiagnosticsReport(runner);
		for (test in tests) {
			runner.addCase(test());
		}
		runner.run();
	}

	function completionHandler(success:Bool) {
		#if instrument
		instrument.coverage.Coverage.endCoverage();
		#end

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

	static function main() {
		new TestMain();
	}
}
