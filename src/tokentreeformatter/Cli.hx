package tokentreeformatter;

import sys.io.File;
import sys.FileSystem;
import tokentreeformatter.Formatter.Result;

class Cli {
	static function main() {
		new Cli();
	}

	var files:Int = 0;
	var verbose:Bool = false;
	var mode:Mode = Format;
	var exitCode:Int = 0;

	function new() {
		var args = Sys.args();
		if (Sys.getEnv("HAXELIB_RUN") == "1") {
			Sys.setCwd(args.pop());
		}

		var paths = [];
		var argHandler = hxargs.Args.generate([@doc("File or directory with .hx files to format (multiple allowed).") ["-s", "--source"
			] => function(path:String) paths.push(path), ["-v"] => function() verbose = true, ["--check"] => function() mode = Check]);
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
		var action = if (mode == Format) "Formatted" else "Checked";
		Sys.println('$action $files files in $seconds s.');

		Sys.exit(exitCode);
	}

	function run(paths:Array<String>) {
		for (path in paths) {
			if (!FileSystem.exists(path)) {
				Sys.println('Skipping \'$path\' (path does not exist)');
				continue;
			}
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
				var action = if (mode == Format) "Formatting" else "Checking";
				Sys.println('$action $path');
			}
			var content:Bytes = File.getBytes(path);
			var result:Result = new Formatter().formatFile({name: path, content: cast content});
			switch (result) {
				case Success(formattedCode):
					files++;
					switch (mode) {
						case Format:
							File.saveContent(path, formattedCode);
						case Check:
							if (formattedCode != content.toString()) {
								Sys.println('Incorrect formatting in $path');
								exitCode = 1;
							}
					}
				case Failure(errorMessage):
					Sys.println('Failed to format $path: $errorMessage');
			}
		}
	}
}

enum Mode {
	Format;
	Check;
}