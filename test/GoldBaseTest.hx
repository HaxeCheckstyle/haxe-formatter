import sys.io.File;
import haxe.io.Bytes;
import haxe.PosInfos;
import haxe.Template;
import massive.munit.Assert;
import formatter.codedata.ParseFile;
import formatter.Formatter.Result;

class GoldBaseTest {
	function goldCheck(fileName:String, unformatted:String, goldCode:String, lineSeparator:String, ?config:String, ?pos:PosInfos) {
		var file:ParseFile = {name: fileName + ".hxtest", content: Bytes.ofString(unformatted), lineSeparator: lineSeparator};
		var formatter:GoldFormatter = new GoldFormatter(config);
		var result:Result = formatter.formatFile(file);
		handleResult(fileName, result, goldCode, pos);

		// second run to make sure result is stable
		switch (result) {
			case Success(formattedCode):
				file = {name: "Test.hx", content: Bytes.ofString(formattedCode)};
				result = formatter.formatFile(file);
				handleResult(fileName, result, goldCode, pos);
			case Failure(errorMessage):
			case Disabled:
		}
	}

	function handleResult(fileName:String, result:Result, goldCode:String, ?pos:PosInfos) {
		var isDisabled:Bool = fileName.startsWith("disabled_");

		switch (result) {
			case Success(formattedCode):
				if (isDisabled) {
					Assert.fail("testcase should be disabled!");
				}
				if (goldCode != formattedCode) {
					File.saveContent("test/formatter-result.txt", '$goldCode\n---\n$formattedCode');
				}
				Assert.areEqual(goldCode, formattedCode, pos);
			case Failure(errorMessage):
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

@:enum
abstract GoldBaseTemplates(String) to String {
	var FieldTemplate = "class Test {
::code::
}";
	var ExprTemplate = "class Test {
	function test() {
		::code::
	}
}";
}
