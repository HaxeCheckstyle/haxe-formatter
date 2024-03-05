import haxe.PosInfos;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import formatter.Formatter;

class SelfTest implements ITest {
	public function new() {}

	public function testSelfSrc() {
		var files:Array<String> = collectAllFileNames("src");
		for (file in files) {
			checkFile(file);
		}
	}

	public function testSelfTest() {
		var files:Array<String> = collectAllFileNames("test");
		for (file in files) {
			checkFile(file);
		}
	}

	public function testSelfSchema() {
		var files:Array<String> = collectAllFileNames("schema");
		for (file in files) {
			checkFile(file);
		}
	}

	function checkFile(fileName:String, ?pos:PosInfos) {
		var code:String = File.getContent(fileName);
		var result = Formatter.format(Code(code, SourceFile(fileName)), Formatter.loadConfig(fileName));
		switch (result) {
			case Success(formattedCode):
				if (code != formattedCode) {
					File.saveContent("test/formatter-result.txt", '$code\n---\n$formattedCode');
				}
				Assert.equals(code, formattedCode, 'Format failed for $fileName', pos);
			case Failure(errorMessage):
				Assert.fail(errorMessage);
			case Disabled:
				Assert.fail("Formatting is disabled");
		}
	}

	static function collectAllFileNames(path:String):Array<String> {
		var items:Array<String> = FileSystem.readDirectory(path);
		var files:Array<String> = [];
		for (item in items) {
			if (item == "." || item == "..") {
				continue;
			}
			var fileName = Path.join([path, item]);
			if (FileSystem.isDirectory(fileName)) {
				files = files.concat(collectAllFileNames(fileName));
				continue;
			}
			if (!item.endsWith(".hx")) {
				continue;
			}
			files.push(Path.join([path, item]));
		}
		return files;
	}
}
