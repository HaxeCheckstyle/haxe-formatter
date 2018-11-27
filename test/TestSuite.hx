import formatter.FormatStatsTest;

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
