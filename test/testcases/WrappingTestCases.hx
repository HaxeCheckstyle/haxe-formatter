package testcases;

@:build(TestCaseMacro.build("test/testcases/wrapping"))
@:build(utest.utils.TestBuilder.build())
class WrappingTestCases extends GoldBaseTest implements ITest {}
