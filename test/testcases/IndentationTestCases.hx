package testcases;

@:build(TestCaseMacro.build("test/testcases/indentation"))
@:build(utest.utils.TestBuilder.build())
class IndentationTestCases extends GoldBaseTest implements ITest {}
