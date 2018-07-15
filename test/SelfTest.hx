import byte.ByteData;
import haxe.io.Path;
import massive.munit.Assert;
import tokentreeformatter.Formatter;
import tokentreeformatter.codedata.ParseFile;
import sys.io.File;
import sys.FileSystem;

class SelfTest {
	@Test
	public function testSelf() {
		var files:Array<String> = collectAllFileNames("src");
		for (file in files) {
			checkFile(file);
		}
	}

	function checkFile(fileName:String) {
		var code:String = File.getContent(fileName);
		var file:ParseFile = {name: fileName, content: ByteData.ofString(code)};
		var formatter:Formatter = new Formatter();
		var formattedCode:String = formatter.formatFile(file);
		Assert.areEqual(code, formattedCode, 'Format failed for $fileName');
	}

	static function collectAllFileNames(path:String):Array<String> {
		var items:Array<String> = FileSystem.readDirectory(path);
		var files:Array<String> = [];
		for (item in items) {
		if (item == "." || item == "..") continue;
		var fileName = Path.join([path, item]);
		if (FileSystem.isDirectory(fileName)) {
			files = files.concat(collectAllFileNames(fileName));
			continue;
		}
		if (!StringTools.endsWith(item, ".hx")) {
			continue;
		}
		files.push(Path.join([path, item]));
		}
		return files;
	}
}