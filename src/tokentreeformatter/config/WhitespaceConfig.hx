package tokentreeformatter.config;

typedef WhitespaceConfig = {
	// ( … )
	@:default(NoneAfter) @:optional var pOpenPolicy:WhitespacePolicy;
	@:default(OnlyAfter) @:optional var pClosePolicy:WhitespacePolicy;
	// [ … ]
	@:default(NoneAfter) @:optional var bkOpenPolicy:WhitespacePolicy;
	@:default(None) @:optional var bkClosePolicy:WhitespacePolicy;
	// { … }
	@:default(Before) @:optional var brOpenPolicy:WhitespacePolicy;
	@:default(Around) @:optional var brClosePolicy:WhitespacePolicy;
	@:default(OnlyBefore) @:optional var objectBrOpenPolicy:WhitespacePolicy;
	@:default(OnlyAfter) @:optional var objectBrClosePolicy:WhitespacePolicy;
	// < … >
	@:default(None) @:optional var typeParamOpenPolicy:WhitespacePolicy;
	@:default(None) @:optional var typeParamClosePolicy:WhitespacePolicy;
	@:default(OnlyAfter) @:optional var commaPolicy:WhitespacePolicy;
	@:default(None) @:optional var dotPolicy:WhitespacePolicy;
	@:default(None) @:optional var dblDotPolicy:WhitespacePolicy;
	@:default(OnlyAfter) @:optional var caseDblDotPolicy:WhitespacePolicy;
	@:default(After) @:optional var objectDblDotPolicy:WhitespacePolicy;
	@:default(None) @:optional var typeDblDotPolicy:WhitespacePolicy;
	@:default(Around) @:optional var ternaryPolicy:WhitespacePolicy;
	@:default(None) @:optional var semicolonPolicy:WhitespacePolicy;
	@:default(After) @:optional var ifPolicy:WhitespacePolicy;
	@:default(After) @:optional var doPolicy:WhitespacePolicy;
	@:default(After) @:optional var whilePolicy:WhitespacePolicy;
	@:default(After) @:optional var forPolicy:WhitespacePolicy;
	@:default(After) @:optional var switchPolicy:WhitespacePolicy;
	@:default(After) @:optional var tryPolicy:WhitespacePolicy;
	@:default(After) @:optional var catchPolicy:WhitespacePolicy;
	@:default(Around) @:optional var binopPolicy:WhitespacePolicy;
	@:default(None) @:optional var intervalPolicy:WhitespacePolicy;
	@:default(true) @:optional var compressSuccessiveParenthesis:Bool;
}