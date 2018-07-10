package tokentreeformatter.config;

typedef WhitespaceConfig = {
	// ( … )
	@:default(tokentreeformatter.config.WhitespacePolicy.NONE_AFTER) @:optional var pOpenPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.NONE) @:optional var pClosePolicy:WhitespacePolicy;
	// [ … ]
	@:default(tokentreeformatter.config.WhitespacePolicy.NONE_AFTER) @:optional var bkOpenPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.NONE) @:optional var bkClosePolicy:WhitespacePolicy;
	// { … }
	@:default(tokentreeformatter.config.WhitespacePolicy.BEFORE) @:optional var brOpenPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AROUND) @:optional var brClosePolicy:WhitespacePolicy;
	// < … >
	@:default(tokentreeformatter.config.WhitespacePolicy.NONE) @:optional var typeParamOpenPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.NONE) @:optional var typeParamClosePolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AFTER) @:optional var commaPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.NONE) @:optional var dotPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.NONE) @:optional var dblDotPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AFTER) @:optional var caseDblDotPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.NONE) @:optional var semicolonPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AROUND) @:optional var binopPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AFTER) @:optional var ifPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AFTER) @:optional var doPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AFTER) @:optional var whilePolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AFTER) @:optional var forPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AFTER) @:optional var functionPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AFTER) @:optional var tryPolicy:WhitespacePolicy;
	@:default(tokentreeformatter.config.WhitespacePolicy.AFTER) @:optional var catchPolicy:WhitespacePolicy;
}