package formatter.config;

typedef FormatterConfig = {
	/**
		turns off formatting for all files in current folder and subfolders
		unless subfolder contains a "hxformat.json"
	**/
	@:default(false) @:optional var disableFormatting:Bool;
	@:default(auto) @:optional var emptyLines:EmptyLinesConfig;
	@:default(auto) @:optional var indentation:IndentationConfig;
	@:default(auto) @:optional var lineEnds:LineEndConfig;
	@:default(auto) @:optional var sameLine:SameLineConfig;
	@:default(auto) @:optional var whitespace:WhitespaceConfig;
	@:default(auto) @:optional var wrapping:WrapConfig;

	/**
		regular expressions matching files to exclude from formatting
		default ist to exclude any ".haxelib" folder
	**/
	@:default(["\\.haxelib"]) @:optional var excludes:Array<String>;
}
