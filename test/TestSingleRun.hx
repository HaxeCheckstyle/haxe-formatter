import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

class TestSingleRun {
	public static inline var SINGLE_RUN_FILE:String = "test/single-run.txt";

	var singleRunTestCase:String;

	public function new() {
		singleRunTestCase = readSingleRun();
	}

	function readSingleRun():String {
		if (FileSystem.exists(SINGLE_RUN_FILE)) {
			var singleRun:String = File.getContent(SINGLE_RUN_FILE).trim();
			if (singleRun.length <= 0) {
				return null;
			}
			return singleRun;
		}
		return null;
	}

	public function isSingleRun():Bool {
		return singleRunTestCase != null;
	}

	public function matchesTest(testName:String):Bool {
		if (!isSingleRun()) {
			return true;
		}
		return normalizePath(singleRunTestCase).endsWith(normalizePath(testName));
	}

	function normalizePath(path:String):String {
		path = Path.normalize(path);
		if (Sys.systemName() == "Windows") {
			return path.toLowerCase();
		}
		return path;
	}
}
