package formatter;

import massive.munit.Assert;
import formatter.FormatStats;

class FormatStatsTest {
	@Before
	public function setup() {
		FormatStats.reset();
	}

	@Test
	public function testSuccessStats() {
		for (i in 0...100) {
			FormatStats.incSuccess();
		}
		Assert.areEqual(100, FormatStats.totalFiles);
		Assert.areEqual(100, FormatStats.successFiles);
	}

	@Test
	public function testFailedStats() {
		for (i in 0...100) {
			FormatStats.incFailed();
		}
		Assert.areEqual(100, FormatStats.totalFiles);
		Assert.areEqual(100, FormatStats.failedFiles);
	}

	@Test
	public function testDisabledStats() {
		for (i in 0...100) {
			FormatStats.incDisabled();
		}
		Assert.areEqual(100, FormatStats.totalFiles);
		Assert.areEqual(100, FormatStats.disabledFiles);
	}

	@Test
	public function testMixedStats() {
		for (i in 0...100) {
			FormatStats.incSuccess();
			FormatStats.incSuccess();
			FormatStats.incSuccess();
			FormatStats.incFailed();
			FormatStats.incFailed();
			FormatStats.incDisabled();
		}
		Assert.areEqual(600, FormatStats.totalFiles);
		Assert.areEqual(300, FormatStats.successFiles);
		Assert.areEqual(200, FormatStats.failedFiles);
		Assert.areEqual(100, FormatStats.disabledFiles);
	}

	@Test
	public function testOrigLines() {
		for (i in 0...100) {
			FormatStats.addOrigLines(25);
		}
		Assert.areEqual(2500, FormatStats.totalLinesOrig);
	}

	@Test
	public function testFormattedLines() {
		for (i in 0...100) {
			FormatStats.addFormattedLines(25);
		}
		Assert.areEqual(2500, FormatStats.totalLinesFormatted);
	}

	@Test
	public function testLines() {
		for (i in 0...100) {
			FormatStats.addOrigLines(23);
			FormatStats.addFormattedLines(13);
		}
		Assert.areEqual(2300, FormatStats.totalLinesOrig);
		Assert.areEqual(1300, FormatStats.totalLinesFormatted);
	}
}
