package formatter;

import haxe.Json;
import json2object.JsonParser;
import sys.io.File;
import sys.FileSystem;
import formatter.Formatter.Result;
import formatter.config.FormatterConfig;

class Cli {
	static function main() {
		new Cli();
	}

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
			if (nodeExists && FileSystem.exists("run.js")) {
				var exitCode = Sys.command("node", ["run.js"].concat(args));
				Sys.exit(exitCode);
			}
		} catch (e:Any) {}
		#end

		if (Sys.getEnv("HAXELIB_RUN") == "1") {
			if (args.length > 0) {
				Sys.setCwd(args.pop());
			}
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

			@doc("Generate a default hxformat.json and exit")
			["--default-config"] => function(path) generateDefaultConfig(path),

			@doc("Display this list of options")
			["--help"] => function() help = true
		]);

		function printHelp() {
			// somehow picks up haxelib.json of hxargs?! - so we use a little trick to make it find ours
			var pack = CompileTime.parseJsonFile("src/formatter/../../haxelib.json");
			Sys.println('Haxe Formatter ${pack.version}');
			Sys.println(argHandler.getDoc());
		}

		try {
			argHandler.parse(args);
		} catch (e:Any) {
			Sys.stderr().writeString(e + "\n");
			printHelp();
			Sys.exit(1);
		}
		if (args.length == 0 || help) {
			printHelp();
			Sys.exit(0);
		}

		var startTime = Date.now().getTime();
		run(paths);

		printStats(Date.now().getTime() - startTime);
		Sys.exit(exitCode);
	}

	function printStats(duration:Float) {
		var seconds = duration / 1000;
		var action = if (mode == Format) "Formatted" else "Checked";

		Sys.println("");
		var fileNumber:String;
		if (FormatStats.successFiles != FormatStats.totalFiles) {
			fileNumber = '${FormatStats.successFiles}/${FormatStats.totalFiles}';
		} else {
			fileNumber = '${FormatStats.successFiles}';
		}
		Sys.println('$action ${fileNumber} files in $seconds s.');
		if (FormatStats.failedFiles > 0) {
			Sys.println('Format failed on ${FormatStats.failedFiles} files');
		}
		if (FormatStats.disabledFiles > 0) {
			Sys.println('Number of disabled files: ${FormatStats.disabledFiles}');
		}
		Sys.println("-------------------------");
		Sys.println('Input lines:  ${FormatStats.totalLinesOrig}');
		Sys.println('Output lines: ${FormatStats.totalLinesFormatted}');
		Sys.println("-------------------------");
	}

	function generateDefaultConfig(path) {
		var parser:JsonParser<FormatterConfig> = new JsonParser<FormatterConfig>();
		var config:FormatterConfig = parser.fromJson("{}", "default-hxformat.json");

		File.saveContent(path, Json.stringify(config, null, "\t"));
		Sys.exit(0);
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
					FormatStats.incSuccess();
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
					FormatStats.incFailed();
					Sys.stderr().writeString('Failed to format $path: $errorMessage\n');
					exitCode = 1;
				case Disabled:
					FormatStats.incDisabled();
			}
		}
	}
}

enum Mode {
	Format;
	Check;
	CheckStability;
}
