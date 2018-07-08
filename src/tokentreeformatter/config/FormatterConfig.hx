package tokentreeformatter.config;

typedef FormatterConfig = {
	@:optional var emptylines:EmptyLinesConfig;
	@:optional var indentation:IndentationConfig;
	@:optional var lineEnds:LineEndConfig;
	@:optional var whitespace:WhitespaceConfig;
	@:optional var wrapping:WrapConfig;
}