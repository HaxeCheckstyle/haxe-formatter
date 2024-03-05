package formatter;

import formatter.FormatStats;

class FormatStatsTest implements ITest {
	public function new() {}

	public function setup() {
		FormatStats.reset();
	}

	public function testSuccessStats() {
		for (i in 0...100) {
			FormatStats.incSuccess();
		}
		Assert.equals(100, FormatStats.totalFiles);
		Assert.equals(100, FormatStats.successFiles);
	}

	public function testFailedStats() {
		for (i in 0...100) {
			FormatStats.incFailed();
		}
		Assert.equals(100, FormatStats.totalFiles);
		Assert.equals(100, FormatStats.failedFiles);
	}

	public function testDisabledStats() {
		for (i in 0...100) {
			FormatStats.incDisabled();
		}
		Assert.equals(100, FormatStats.totalFiles);
		Assert.equals(100, FormatStats.disabledFiles);
	}

	public function testMixedStats() {
		for (i in 0...100) {
			FormatStats.incSuccess();
			FormatStats.incSuccess();
			FormatStats.incSuccess();
			FormatStats.incFailed();
			FormatStats.incFailed();
			FormatStats.incDisabled();
		}
		Assert.equals(600, FormatStats.totalFiles);
		Assert.equals(300, FormatStats.successFiles);
		Assert.equals(200, FormatStats.failedFiles);
		Assert.equals(100, FormatStats.disabledFiles);
	}

	public function testOrigLines() {
		for (i in 0...100) {
			FormatStats.addOrigLines(25);
		}
		Assert.equals(2500, FormatStats.totalLinesOrig);
	}

	public function testFormattedLines() {
		for (i in 0...100) {
			FormatStats.addFormattedLines(25);
		}
		Assert.equals(2500, FormatStats.totalLinesFormatted);
	}

	public function testLines() {
		for (i in 0...100) {
			FormatStats.addOrigLines(23);
			FormatStats.addFormattedLines(13);
		}
		Assert.equals(2300, FormatStats.totalLinesOrig);
		Assert.equals(1300, FormatStats.totalLinesFormatted);
	}
}
