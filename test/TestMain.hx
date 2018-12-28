import haxe.EntryPoint;
import sys.io.File;
import massive.munit.TestRunner;
import mcover.coverage.munit.client.MCoverPrintClient;
#if codecov_json
import mcover.coverage.client.CodecovJsonPrintClient;
#else
import mcover.coverage.client.LcovPrintClient;
#end
import mcover.coverage.MCoverage;
import unittesthelper.munit.TestAdapterRunner;

class TestMain {
	public function new() {
		var suites:Array<Class<massive.munit.TestSuite>> = [TestSuite];
		var client:MCoverPrintClient = new MCoverPrintClient();
		#if codecov_json
		MCoverage.getLogger().addClient(new CodecovJsonPrintClient());
		#else
		MCoverage.getLogger().addClient(new LcovPrintClient("Formatter Unittests"));
		#end

		#if detailed_coverage
		client.includeClassAndPackageBreakdowns = true;
		client.includeMissingBlocks = true;
		#end
		var runner:TestRunner = new TestAdapterRunner(client);
		runner.completionHandler = completionHandler;
		#if (neko || cpp || hl)
		EntryPoint.addThread(function() {
			while (true) {
				Sys.sleep(1.0);
			}
		});
		#end
		runner.run(suites);
		EntryPoint.run();
	}

	function completionHandler(success:Bool) {
		if (success) {
			File.saveContent("test/formatter-result.txt", "\n---\n");
		}
		#if eval
		if (!success) {
			Sys.exit(1);
		}
		#else
		Sys.exit(success ? 0 : 1);
		#end
	}

	static function main() {
		new TestMain();
	}
}
