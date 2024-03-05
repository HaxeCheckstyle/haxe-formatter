package testcases;

@:build(TestCaseMacro.build("test/testcases/missing"))
@:build(utest.utils.TestBuilder.build())
class MissingTestCases extends GoldBaseTest implements ITest {}
