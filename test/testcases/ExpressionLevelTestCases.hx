package testcases;

@:build(TestCaseMacro.build("test/testcases/expressionlevel"))
class ExpressionLevelTestCases extends GoldBaseTest {
	public function new() {
		entryPoint = EXPRESSION_LEVEL;
	}
}
