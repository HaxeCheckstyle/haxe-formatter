import formatter.FormatStatsTest;
import testcases.EmptyLinesTestCases;
import testcases.IndentationTestCases;
import testcases.LineEndsTestCases;
import testcases.MissingTestCases;
import testcases.Other;
import testcases.SameLineTestCases;
import testcases.WhitespaceTestCases;
import testcases.WrappingTestCases;

class TestSuite extends massive.munit.TestSuite {
	public function new() {
		super();

		CompileTime.importPackage("testcases");

		var singleRun:TestSingleRun = new TestSingleRun();
		if (!singleRun.isSingleRun()) {
			add(SelfTest);
			add(FormatStatsTest);
		}

		var tests = CompileTime.getAllClasses(GoldBaseTest);
		for (testClass in tests) {
			add(testClass);
		}
	}
}
