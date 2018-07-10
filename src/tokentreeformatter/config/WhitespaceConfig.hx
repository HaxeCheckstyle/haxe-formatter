package tokentreeformatter.config;

typedef WhitespaceConfig = {
	// ( … )
	@:default(NONE_AFTER) @:optional var pOpenPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var pClosePolicy:WhitespacePolicy;
	// [ … ]
	@:default(NONE_AFTER) @:optional var bkOpenPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var bkClosePolicy:WhitespacePolicy;
	// { … }
	@:default(BEFORE) @:optional var brOpenPolicy:WhitespacePolicy;
	@:default(AROUND) @:optional var brClosePolicy:WhitespacePolicy;
	// < … >
	@:default(NONE) @:optional var typeParamOpenPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var typeParamClosePolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var commaPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var dotPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var dblDotPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var caseDblDotPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var semicolonPolicy:WhitespacePolicy;
	@:default(AROUND) @:optional var binopPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var ifPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var doPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var whilePolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var forPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var functionPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var tryPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var catchPolicy:WhitespacePolicy;
}