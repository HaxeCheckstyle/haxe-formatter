package formatter;

import sys.io.File;
import sys.FileSystem;
import formatter.Formatter.Result;

class Cli {
	// TODO: use a macro to read this from haxelib.json
	static inline var VERSION = "1.0.0";

	static function main() {
		new Cli();
	}

	var files:Int = 0;
	var verbose:Bool = false;
	var mode:Mode = Format;
	var exitCode:Int = 0;

	function new() {
		var args = Sys.args();

		#if neko
		// use the faster JS version if possible
		try {
			var process = new sys.io.Process("node", ["-v"]);
			var nodeExists = process.exitCode() == 0;
			process.close();
			if (nodeExists) {
				var exitCode = Sys.command("node", ["run.js"].concat(args));
				Sys.exit(exitCode);
			}
		} catch (e:Any) {}
		#end

		if (Sys.getEnv("HAXELIB_RUN") == "1") {
			Sys.setCwd(args.pop());
		}

		var paths = [];
		var help = false;
		var argHandler = hxargs.Args.generate([
			@doc("File or directory with .hx files to format (multiple allowed)")
			["-s", "--source"] => function(path:String) paths.push(path),

			@doc("Print additional information")
			["-v"] => function() verbose = true,

			@doc("Don't format, only check if files are formatted correctly")
			["--check"] => function() mode = Check,

			#if debug
			@doc("Don't format, only check if formatting is stable")
			["--check-stability"] => function() mode = CheckStability,
			#end

			@doc("Display this list of options")
			["--help"] => function() help = true
		]);

		function printHelp() {
			Sys.println('Haxe Formatter $VERSION');
			Sys.println(argHandler.getDoc());
		}

		try {
			argHandler.parse(args);
		} catch (e:Any) {
			Sys.println(e + "\n");
			printHelp();
			Sys.exit(1);
		}
		if (args.length == 0 || help) {
			printHelp();
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
			var result:Result = new Formatter().formatFile({name: path, content: content});
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
						case CheckStability:
							var secondResult = new Formatter().formatFile({name: path, content: Bytes.ofString(formattedCode)});
							function unstable() {
								Sys.println('Unstable formatting in $path');
								exitCode = 1;
							}
							switch (secondResult) {
								case Success(formattedCode2) if (formattedCode != formattedCode2):
									unstable();
								case Failure(errorMessage):
									unstable();
								case _:
							}
					}
				case Failure(errorMessage):
					Sys.println('Failed to format $path: $errorMessage');
					exitCode = 1;
				case Disabled:
			}
		}
	}
}

enum Mode {
	Format;
	Check;
	CheckStability;
}
