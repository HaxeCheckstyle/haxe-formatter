package tokentreeformatter.config;

typedef WhitespaceConfig = {
	// ( … )
	@:optional var pOpenPolicy:WhitespacePolicy;
	@:optional var pClosePolicy:WhitespacePolicy;
	// [ … ]
	@:optional var bkOpenPolicy:WhitespacePolicy;
	@:optional var bkClosePolicy:WhitespacePolicy;
	// { … }
	@:optional var brOpenPolicy:WhitespacePolicy;
	@:optional var brClosePolicy:WhitespacePolicy;
	// < … >
	@:optional var typeParamOpenPolicy:WhitespacePolicy;
	@:optional var typeParamClosePolicy:WhitespacePolicy;
	@:optional var commaPolicy:WhitespacePolicy;
	@:optional var dotPolicy:WhitespacePolicy;
	@:optional var semicolonPolicy:WhitespacePolicy;
	@:optional var binopPolicy:WhitespacePolicy;
	@:optional var ifPolicy:WhitespacePolicy;
	@:optional var doPolicy:WhitespacePolicy;
	@:optional var whilePolicy:WhitespacePolicy;
	@:optional var forPolicy:WhitespacePolicy;
	@:optional var functionPolicy:WhitespacePolicy;
	@:optional var tryPolicy:WhitespacePolicy;
	@:optional var catchPolicy:WhitespacePolicy;
}

@:enum
abstract LeftCurlyPolicy(String) {
	var EOL = "eol";
	var NL = "nl";
}