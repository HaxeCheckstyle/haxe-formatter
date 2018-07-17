import sys.io.File;
import sys.FileSystem;

class TestSingleRun {
	public static inline var SINGLE_RUN_FILE:String = "testSingleRun.txt";

	var singleRunTestCase:String;

	public function new() {
		singleRunTestCase = readSingleRun();
	}

	function readSingleRun():String {
		if (FileSystem.exists(SINGLE_RUN_FILE)) {
			var singleRun:String = StringTools.trim(File.getContent(SINGLE_RUN_FILE));
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
		return singleRunTestCase == testName;
	}
}
