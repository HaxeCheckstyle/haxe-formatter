package tokentreeformatter.config;

typedef FormatterConfig = {
	@:default(auto) @:optional var emptylines:EmptyLinesConfig;
	@:default(auto) @:optional var indentation:IndentationConfig;
	@:default(auto) @:optional var lineEnds:LineEndConfig;
	@:default(auto) @:optional var whitespace:WhitespaceConfig;
	@:default(auto) @:optional var wrapping:WrapConfig;
}