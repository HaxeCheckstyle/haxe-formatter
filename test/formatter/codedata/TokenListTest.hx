package formatter.codedata;

import haxe.PosInfos;
import haxe.io.Bytes;
import massive.munit.Assert;

class TokenListTest {
	@Test
	public function testGetTokenAt() {
		var tokenList:TokenList = makeTokenList(FormatStatsTestCode.CodeSample);
		checkToken(tokenList, 0, 0, "class");
		checkToken(tokenList, 5, 0, "class");
		checkToken(tokenList, 7, 1, "Main");
		checkToken(tokenList, 12, 2, "{");
		checkToken(tokenList, 13, 2, "{");
		checkToken(tokenList, 14, 3, "public");
		checkToken(tokenList, 41, 9, "trace");
	}

	@Test
	public function testInvalidGetTokenAt() {
		var tokenList:TokenList = makeTokenList(FormatStatsTestCode.CodeSample);
		try {
			tokenList.getTokenAtOffset(-1);
			Assert.fail("previous call should not succeed");
		} catch (e:Any) {}
		try {
			tokenList.getTokenAtOffset(64);
			Assert.fail("previous call should not succeed");
		} catch (e:Any) {}
		tokenList = makeTokenList("");
		try {
			tokenList.getTokenAtOffset(1);
			Assert.fail("previous call should not succeed");
		} catch (e:Any) {}
	}

	function checkToken(tokenList:TokenList, offset:Int, expectedIndex:Int, expectedText:String, ?pos:PosInfos) {
		var tokenInfo:Null<TokenInfo> = tokenList.getTokenAtOffset(offset);
		Assert.isNotNull(tokenInfo, pos);
		Assert.isNotNull(tokenInfo.token, pos);
		Assert.areEqual(expectedIndex, tokenInfo.token.index, pos);
		Assert.areEqual(expectedText, tokenInfo.token.toString());
	}

	function makeTokenList(code:String):TokenList {
		var content:Bytes = Bytes.ofString(code);
		var input:FormatterInputData = {
			fileName: "test.hx",
			content: content,
			config: null,
			entryPoint: TypeLevel,
			lineSeparator: null,
			range: null
		}
		var parsedCode:ParsedCode = new ParsedCode(input);
		return parsedCode.tokenList;
	}
}

enum abstract FormatStatsTestCode(String) to String {
	var CodeSample = "
class Main {

	public function new () {
		trace('foo');
	}
}
	";
}
