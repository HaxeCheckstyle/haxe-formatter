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
		var pipemode = false;
		var argHandler = hxargs.Args.generate([
			@doc("File or directory with .hx files to format (multiple allowed)")
			["-s", "--source"] => function(path:String) paths.push(path),

			@doc("Read code from stdin and print formatted output to stdout (needs _one_ -s <path> for reference in configuration detection)")
			["--stdin"] => function() pipemode = true,

			@doc("Print additional information")
			["-v"] => function() verbose = true,

			@doc("Don't format, only check if files are formatted correctly")
			["--check"] => function() mode = Check,

			#if debug
			@doc("Don't format, only check if formatting is stable")
			["--check-stability"] => function() mode = CheckStability,
			#end

			@doc("Generate a default hxformat.json to a file and exit")
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

		if (pipemode) {
			runPipe(paths);
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
		if (FileSystem.isDirectory(path)) {
			Sys.println('"$path" is a directory, not a file');
			Sys.exit(1);
		}
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

	function runPipe(paths:Array<String>) {
		var content:Null<Bytes> = null;
		try {
			#if nodejs
			content = readNodeJsBytes(Sys.stdin());
			#else
			content = Sys.stdin().readAll();
			#end

			if (content == null) {
				Sys.stderr().writeString("Could not read anything from STDIN");
				Sys.exit(-1);
			}
			if (paths.length != 1) {
				Sys.println(content);
				Sys.stderr().writeString("Please use exactly one `--source <path>` parameter");
				Sys.exit(3);
			}
			if (!FileSystem.exists(paths[0])) {
				Sys.println(content);
				Sys.stderr().writeString('Could not find "${paths[0]}"');
				Sys.exit(3);
			}
			var config = Formatter.loadConfig(paths[0]);

			var result:Result = Formatter.format(Code(content.toString()), config);
			switch (result) {
				case Success(formattedCode):
					Sys.println(formattedCode);
					Sys.exit(0);
				case Failure(errorMessage):
					Sys.println(content);
					Sys.stderr().writeString("Format failed: " + errorMessage);
					Sys.exit(2);
				case Disabled:
					Sys.println(content);
					Sys.stderr().writeString('Formatting is disabled in "${paths[0]}"');
					Sys.exit(1);
			}
		} catch (e:Any) {
			if (content != null) {
				Sys.println(content);
			}
			Sys.stderr().writeString('Format failed: ${e}');
			Sys.exit(-1);
		}
	}

	function formatFile(path:String) {
		if (path.endsWith(".hx")) {
			if (verbose) {
				var action = if (mode == Format) "Formatting" else "Checking";
				Sys.println('$action $path');
			}
			var content:String = File.getContent(path);
			var config = Formatter.loadConfig(path);
			var result:Result = Formatter.format(Code(content), config);
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
							var secondResult = Formatter.format(Code(formattedCode), config);
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

	#if nodejs
	function readNodeJsBytes(stdIn:haxe.io.Input):Bytes {
		var bufsize:Int = 1 << 14;
		var buf = Bytes.alloc(bufsize);
		var total = new haxe.io.BytesBuffer();
		while (true) {
			var len = stdIn.readBytes(buf, 0, bufsize);
			if (len == 0) {
				break;
			}
			total.addBytes(buf, 0, len);
		}
		return total.getBytes();
	}
	#end
}

enum Mode {
	Format;
	Check;
	CheckStability;
}
