package tokentreeformatter;

import sys.io.File;
import sys.FileSystem;

class Cli {
	static function main() {
		new Cli();
	}

	var filesFormatted:Int = 0;
	var verbose:Bool;

	function new() {
		var args = Sys.args();
		if (Sys.getEnv("HAXELIB_RUN") == "1") {
			args.pop();
		}

		var paths = [];
		var argHandler = hxargs.Args.generate([@doc("File or directory with .hx files to format (multiple allowed).") ["-s", "--source"
			] => function(path:String) paths.push(path), ["-v"] => function(verbose:Bool) this.verbose = verbose]);
		argHandler.parse(args);
		if (args.length == 0) {
			Sys.println("Haxe Formatter");
			Sys.println(argHandler.getDoc());
			Sys.exit(0);
		}

		var startTime = Date.now().getTime();
		run(paths);

		var duration = Date.now().getTime() - startTime;
		Sys.println("");
		var seconds = duration / 1000;
		Sys.println('Formatted $filesFormatted files in $seconds s.');
	}

	function run(paths:Array<String>) {
		for (path in paths) {
			if (FileSystem.isDirectory(path)) {
				run([for (file in FileSystem.readDirectory(path)) '$path/$file']);
			} else {
				formatFile(path);
			}
		}
	}

	function formatFile(path:String) {
		if (path.endsWith(".hx")) {
			if (verbose) {
				Sys.println('Formatting $path');
			}
			var formattedFile = new Formatter().formatFile({
				name: path, content: cast File.getBytes(path)
				});
			if (formattedFile == null) {
				Sys.println('Failed to format $path');
			} else {
				filesFormatted++;
				File.saveContent(path, formattedFile);
			}
		}
	}
}