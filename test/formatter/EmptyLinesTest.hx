package formatter;

import haxe.PosInfos;
import haxe.io.BytesBuffer;
import formatter.Formatter;
import formatter.config.Config;

class EmptyLinesTest implements ITest {
	public function new() {}

	public function testEmptyLines() {
		var lines:Array<String> = (EmptyLinesText1 : String).split("\n").map(function(s) return s.trim());
		var formatted:String = format(lines.join("\n"));
		var formattedLines:Array<String> = formatted.split("\n").map(function(s) return s.ltrim());
		compareLines(lines, formattedLines);

		formatted = format(lines.join("\n"));
		formattedLines = formatted.split("\n").map(function(s) return s.ltrim());
		compareLines(lines, formattedLines);

		var buf:StringBuf = new StringBuf();
		var odd:Bool = true;
		for (line in lines) {
			buf.add(line);
			if (odd) {
				buf.add("\n");
			} else {
				buf.add("\r\n");
			}
			odd = !odd;
		}
		formatted = format(buf.toString());
		formattedLines = formatted.split("\n").map(function(s) return s.ltrim());
		compareLines(lines, formattedLines);
	}

	public function testBOMEmptyLines() {
		var lines:Array<String> = (EmptyLinesText1 : String).split("\n").map(function(s) return s.trim());

		var formatted:String = format(lines.join("\n"));
		var formattedLines:Array<String> = formatted.split("\n").map(function(s) return s.ltrim());
		compareLines(lines, formattedLines);

		var byteBuffer:BytesBuffer = new BytesBuffer();
		byteBuffer.addByte(0xEF);
		byteBuffer.addByte(0xBB);
		byteBuffer.addByte(0xBF);
		byteBuffer.addString(lines.join("\n"));

		formatted = format(byteBuffer.getBytes().toString());
		formattedLines = formatted.split("\n").map(function(s) return s.ltrim());
		compareLines(lines, formattedLines);

		byteBuffer = new BytesBuffer();
		byteBuffer.addByte(0xEF);
		byteBuffer.addByte(0xBB);
		byteBuffer.addByte(0xBF);
		byteBuffer.addString(lines.join("\n"));

		formatted = format(byteBuffer.getBytes().toString());
		formattedLines = formatted.split("\n").map(function(s) return s.ltrim());
		compareLines(lines, formattedLines);
	}

	public function testCommentEmptyLines() {
		var lines:Array<String> = (EmptyLinesText1 : String).split("\n").map(function(s) return s.trim());
		lines.unshift("// äääääääääääääääääääööööööööööööööööööööüüüüüüüüüüüüüüüüüüüüüüßßßßßßßßßßßßßßßßßææææææææææææææææðððððððððððð€€€€€€€€€€€€€€¶¶¶¶¶¶¶¶¶¶¶đđđđđđđłł");
		lines.pop();
		lines.push("// äääääääääääääääääääööööööööööööööööööööüüüüüüüüüüüüüüüüüüüüüüßßßßßßßßßßßßßßßßßææææææææææææææææðððððððððððð€€€€€€€€€€€€€€¶¶¶¶¶¶¶¶¶¶¶đđđđđđđłł");
		lines.push("");
		var formatted:String = format(lines.join("\n"));
		var formattedLines:Array<String> = formatted.split("\n").map(function(s) return s.ltrim());
		compareLines(lines, formattedLines);

		formatted = format(lines.join("\n"));
		formattedLines = formatted.split("\n").map(function(s) return s.ltrim());
		compareLines(lines, formattedLines);
	}

	function compareLines(lines:Array<String>, formattedLines:Array<String>, ?pos:PosInfos) {
		Assert.equals(lines.length, formattedLines.length, pos);
		var index:Int = 0;
		for (i in 0...lines.length) {
			Assert.equals(lines[i], formattedLines[i], pos);
		}
	}

	function format(unformatted:String, ?pos:PosInfos):String {
		var config = new Config();
		config.readConfigFromString("{}", "goldhxformat.json");
		var result:Result = Formatter.format(Code(unformatted, Snippet), config, null, TypeLevel);
		switch (result) {
			case Success(formattedCode):
				return formattedCode;
			case Failure(errorMessage):
				Assert.fail(errorMessage, pos);
			case Disabled:
		}
		Assert.fail("failed to format", pos);
		return null;
	}
}

enum abstract EmptyLinesTests(String) to String {
	var EmptyLinesText1 = "class Test {
	function test() {
		trace(oldText);

		switch (result) {
			case Success(formattedCode):
				formattedCode.replace(oldText, newText);
			case Failure(errorMessage):
				formattedCode.replace(oldText, newText);
			case Disabled:
				formattedCode.replace(oldText, newText);
		}

		var obj = new Point(100, 200);
		obj.x += 100;

		trace(oldText);
		trace(oldText);
	}
}
";
}
