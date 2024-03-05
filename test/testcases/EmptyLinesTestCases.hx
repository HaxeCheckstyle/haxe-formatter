package testcases;

@:build(TestCaseMacro.build("test/testcases/emptylines"))
@:build(utest.utils.TestBuilder.build())
class EmptyLinesTestCases extends GoldBaseTest implements ITest {}
