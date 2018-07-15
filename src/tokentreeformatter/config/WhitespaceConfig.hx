package tokentreeformatter.config;

typedef WhitespaceConfig = {
	// ( … )
	@:default(NONE_AFTER) @:optional var pOpenPolicy:WhitespacePolicy;
	@:default(ONLY_AFTER) @:optional var pClosePolicy:WhitespacePolicy;
	// [ … ]
	@:default(NONE_AFTER) @:optional var bkOpenPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var bkClosePolicy:WhitespacePolicy;
	// { … }
	@:default(BEFORE) @:optional var brOpenPolicy:WhitespacePolicy;
	@:default(AROUND) @:optional var brClosePolicy:WhitespacePolicy;
	@:default(ONLY_BEFORE) @:optional var objectBrOpenPolicy:WhitespacePolicy;
	@:default(ONLY_AFTER) @:optional var objectBrClosePolicy:WhitespacePolicy;
	// < … >
	@:default(NONE) @:optional var typeParamOpenPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var typeParamClosePolicy:WhitespacePolicy;
	@:default(ONLY_AFTER) @:optional var commaPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var dotPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var dblDotPolicy:WhitespacePolicy;
	@:default(ONLY_AFTER) @:optional var caseDblDotPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var objectDblDotPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var typeDblDotPolicy:WhitespacePolicy;
	@:default(AROUND) @:optional var ternaryPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var semicolonPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var ifPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var doPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var whilePolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var forPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var switchPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var tryPolicy:WhitespacePolicy;
	@:default(AFTER) @:optional var catchPolicy:WhitespacePolicy;
	@:default(AROUND) @:optional var binopPolicy:WhitespacePolicy;
	@:default(NONE) @:optional var intervalPolicy:WhitespacePolicy;
	@:default(true) @:optional var compressSuccessiveParenthesis:Bool;
}