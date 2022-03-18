package testcases;

import haxe.PosInfos;
import massive.munit.Assert;
import formatter.Formatter;
import formatter.config.Config;

@:build(TestCaseMacro.build("test/testcases/formatrange"))
class FormatRangeTestCases extends GoldBaseTest {
	override public function goldCheck(fileName:String, unformatted:String, goldCode:String, lineSeparator:String, ?configString:String, ?pos:PosInfos) {
		var config = new Config();
		config.readConfigFromString(configString, "goldhxformat.json");

		var startIndex:Int = unformatted.indexOf(">[");
		if (startIndex < 0) {
			Assert.fail("testcase has no start marker!");
		}
		unformatted = unformatted.replace(">[", "");
		var endIndex:Int = unformatted.indexOf("]<");
		if (endIndex < 0) {
			Assert.fail("testcase has no end marker!");
		}
		unformatted = unformatted.replace("]<", "");

		var result:Result = Formatter.format(Code(unformatted, SourceFile(fileName)), config, lineSeparator, entryPoint,
			{startPos: startIndex, endPos: endIndex});
		handleResult(fileName, result, goldCode, pos);
	}
}
