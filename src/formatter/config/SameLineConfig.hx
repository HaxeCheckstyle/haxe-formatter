package formatter.config;

typedef SameLineConfig = {
	@:default(Next) @:optional var ifBody:SameLinePolicy;
	@:default(Next) @:optional var elseBody:SameLinePolicy;
	@:default(Same) @:optional var ifElse:SameLinePolicy;
	@:default(Same) @:optional var elseIf:SameLinePolicy;
	@:default(Same) @:optional var expressionIf:SameLinePolicy;

	/**
		will place if with one expression in a block in one line (requires "expressionIf" = "same")
		var foo = if (bar) { ""; } else { ""; };
	**/
	@:default(false) @:optional var expressionIfWithBlocks:Bool;

	/**
		should non block body of "for" be on same line or next
	**/
	@:default(Next) @:optional var forBody:SameLinePolicy;
	@:default(Same) @:optional var comprehensionFor:SameLinePolicy;

	/**
		should non block body of "while" be on same line or next
	**/
	@:default(Next) @:optional var whileBody:SameLinePolicy;

	/**
		should non block body of "do…while" be on same line or next
	**/
	@:default(Next) @:optional var doWhileBody:SameLinePolicy;

	/**
		should non block body of "while" of "do…while" be on same line or next
	**/
	@:default(Same) @:optional var doWhile:SameLinePolicy;
	@:default(Next) @:optional var tryBody:SameLinePolicy;
	@:default(Next) @:optional var catchBody:SameLinePolicy;
	@:default(Same) @:optional var tryCatch:SameLinePolicy;
	@:default(Next) @:optional var caseBody:SameLinePolicy;
	@:default(Same) @:optional var expressionCase:SameLinePolicy;
	@:default(Same) @:optional var expressionTry:SameLinePolicy;
	@:default(Next) @:optional var functionBody:SameLinePolicy;
	@:default(Same) @:optional var anonFunctionBody:SameLinePolicy;
}

@:enum
abstract SameLinePolicy(String) {
	var Same = "same";
	var Next = "next";
}
