import haxe.Timer;

class Build {
	public static function main() {
		callLix("buildJsNode.hxml", "run.js");
		callLix("buildJsBrowser.hxml", "runBrowser.js");
		callLix("buildNeko.hxml", "run.n");
		callLix("buildJava.hxml", "Cli.jar");
		callLix("buildSchema.hxml", "JSON schema");
	}

	public static function callLix(buildFile:String, title:String) {
		var startTime = Timer.stamp();
		Sys.command("npx", ["haxe", buildFile]);
		Sys.println('building $title (${Timer.stamp() - startTime})');
	}
}
