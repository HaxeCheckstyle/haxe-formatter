package formatter.config;

typedef WhitespaceConfig = {
	// ( … )
	@:default(NoneAfter) @:optional var openingParenPolicy:WhitespacePolicy;
	@:default(OnlyAfter) @:optional var closingParenPolicy:WhitespacePolicy;
	// [ … ]
	@:default(NoneAfter) @:optional var openingBracketPolicy:WhitespacePolicy;
	@:default(None) @:optional var closingBracketPolicy:WhitespacePolicy;
	// { … }
	@:default(Before) @:optional var openingBracePolicy:WhitespacePolicy;
	@:default(Around) @:optional var closingBracePolicy:WhitespacePolicy;
	@:default(OnlyBefore) @:optional var objectOpeningBracePolicy:WhitespacePolicy;
	@:default(OnlyAfter) @:optional var objectClosingBracePolicy:WhitespacePolicy;
	// < … >
	@:default(None) @:optional var typeParamOpenPolicy:WhitespacePolicy;
	@:default(None) @:optional var typeParamClosePolicy:WhitespacePolicy;
	@:default(Around) @:optional var typeExtensionPolicy:WhitespacePolicy;
	@:default(OnlyAfter) @:optional var commaPolicy:WhitespacePolicy;
	@:default(None) @:optional var dotPolicy:WhitespacePolicy;
	@:default(None) @:optional var colonPolicy:WhitespacePolicy;
	@:default(OnlyAfter) @:optional var caseColonPolicy:WhitespacePolicy;
	@:default(After) @:optional var objectFieldColonPolicy:WhitespacePolicy;
	@:default(None) @:optional var typeHintColonPolicy:WhitespacePolicy;
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
	/**
		should formatter compress whitespae for successive parenthesis `( [ {` vs. `([{`
	**/
	@:default(true) @:optional var compressSuccessiveParenthesis:Bool;
}
