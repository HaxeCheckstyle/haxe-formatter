import sys.io.File;
import byte.ByteData;
import haxe.PosInfos;
import haxe.Template;
import massive.munit.Assert;
import tokentreeformatter.codedata.ParseFile;
import tokentreeformatter.Formatter.Result;

class GoldBaseTest {
	function goldCheck(unformatted:String, goldCode:String, ?config:String, ?pos:PosInfos) {
		var file:ParseFile = {name: "Test.hx", content: ByteData.ofString(unformatted)};
		var formatter:GoldFormatter = new GoldFormatter(config);
		var result:Result = formatter.formatFile(file);
		switch (result) {
			case Success(formattedCode):
				if (goldCode != formattedCode) {
					File.saveContent("test/formatter-result.txt", '$goldCode\n---\n$formattedCode');
				}
				Assert.areEqual(goldCode, formattedCode, pos);
			case Failure(errorMessage):
				Assert.fail(errorMessage, pos);
			case Disabled:
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
		goldCheck(unformattedFull, formattedFull, config, pos);
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
