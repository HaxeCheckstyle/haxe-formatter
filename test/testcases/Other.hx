package testcases;

@:build(TestCaseMacro.build("test/testcases/other"))
@:build(utest.utils.TestBuilder.build())
class Other extends GoldBaseTest implements ITest {}
