import haxe.PosInfos;
import haxe.Template;
import sys.io.File;
import formatter.Formatter;
import formatter.config.Config;
import massive.munit.Assert;
import tokentree.TokenTreeBuilder.TokenTreeEntryPoint;

class GoldBaseTest {
	var entryPoint:TokenTreeEntryPoint = null;

	function goldCheck(fileName:String, unformatted:String, goldCode:String, lineSeparator:String, ?configString:String, ?pos:PosInfos) {
		var config = new Config();
		config.readConfigFromString(configString, "goldhxformat.json");
		var result:Result = Formatter.format(Code(unformatted, SourceFile(fileName)), config, lineSeparator, entryPoint);
		handleResult(fileName, result, goldCode, pos);

		// second run to make sure result is stable
		switch (result) {
			case Success(formattedCode):
				result = Formatter.format(Code(formattedCode, SourceFile(fileName)), config, lineSeparator, entryPoint);
				handleResult(fileName, result, goldCode, pos);
			case Failure(errorMessage):
			case Disabled:
		}
	}

	function handleResult(fileName:String, result:Result, goldCode:String, ?pos:PosInfos) {
		var file = new haxe.io.Path(fileName).file;
		var isDisabled:Bool = file.startsWith("disabled_");
		var isFailing:Bool = file.startsWith("failing_");

		switch (result) {
			case Success(formattedCode):
				if (isDisabled) {
					Assert.fail("testcase should be disabled!");
				}
				if (isFailing) {
					Assert.fail("testcase should be failing!");
				}
				if (goldCode != formattedCode) {
					File.saveContent("test/formatter-result.txt", '$goldCode\n---\n$formattedCode');
				}
				Assert.areEqual(goldCode, formattedCode, pos);
			case Failure(errorMessage):
				if (isFailing) {
					return;
				}
				Assert.fail(errorMessage, pos);
			case Disabled:
				if (isDisabled) {
					return;
				}
				Assert.fail("Formatting is disabled", pos);
		}
	}

	function goldCheckField(unformatted:String, gold:String, ?config:String, ?pos:PosInfos) {
		goldCheckTemplate(FieldTemplate, unformatted, gold, config, pos);
	}

	function goldCheckExpr(unformatted:String, gold:String, ?config:String, ?pos:PosInfos) {
		goldCheckTemplate(ExprTemplate, unformatted, gold, config, pos);
	}

	function goldCheckTemplate(template:GoldBaseTemplates, unformatted:String, gold:String, ?config:String, ?pos:PosInfos) {
		var template:Template = new Template(template);
		var unformattedFull:String = template.execute({code: unformatted});
		var formattedFull:String = template.execute({code: gold});
		goldCheck("Test", unformattedFull, formattedFull, config, pos);
	}
}

enum abstract GoldBaseTemplates(String) to String {
	var FieldTemplate = "class Test {
::code::
}";
	var ExprTemplate = "class Test {
	function test() {
		::code::
	}
}";
}
