package testcases;

@:build(TestCaseMacro.build("test/testcases/expressionlevel"))
@:build(utest.utils.TestBuilder.build())
class ExpressionLevelTestCases extends GoldBaseTest implements ITest {
	public function new() {
		super();
		entryPoint = ExpressionLevel;
	}
}
