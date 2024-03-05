package testcases;

@:build(TestCaseMacro.build("test/testcases/lineends"))
@:build(utest.utils.TestBuilder.build())
class LineEndsTestCases extends GoldBaseTest implements ITest {}
