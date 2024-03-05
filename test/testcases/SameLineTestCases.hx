package testcases;

@:build(TestCaseMacro.build("test/testcases/sameline"))
@:build(utest.utils.TestBuilder.build())
class SameLineTestCases extends GoldBaseTest implements ITest {}
