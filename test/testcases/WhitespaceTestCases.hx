package testcases;

@:build(TestCaseMacro.build("test/testcases/whitespace"))
@:build(utest.utils.TestBuilder.build())
class WhitespaceTestCases extends GoldBaseTest implements ITest {}
