import haxe.Timer;

class Build {
	private static var exitCode:Int = 0;

	public static function main() {
		callLix("buildJsNode.hxml", "run.js");
		callLix("buildJsBrowser.hxml", "runBrowser.js");
		callLix("buildNeko.hxml", "run.n");
		callLix("buildJava.hxml", "Cli.jar");
		callLix("buildSchema.hxml", "JSON schema");
		Sys.exit(exitCode);
	}

	public static function callLix(buildFile:String, title:String) {
		var startTime = Timer.stamp();
		var result:Int = Sys.command("npx", ["haxe", buildFile]);
		Sys.println('building $title (${Timer.stamp() - startTime})');
		if (result != 0) {
			exitCode = result;
		}
	}
}
