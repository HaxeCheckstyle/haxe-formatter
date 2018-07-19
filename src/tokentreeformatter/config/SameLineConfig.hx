package tokentreeformatter.config;

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
	@:default(Next) @:optional var forBody:SameLinePolicy;
	@:default(Same) @:optional var comprehensionFor:SameLinePolicy;
	@:default(Next) @:optional var whileBody:SameLinePolicy;
	@:default(Next) @:optional var doWhileBody:SameLinePolicy;
	@:default(Next) @:optional var tryBody:SameLinePolicy;
	@:default(Next) @:optional var catchBody:SameLinePolicy;
	@:default(Same) @:optional var tryCatch:SameLinePolicy;
	@:default(Same) @:optional var anonObjects:SameLinePolicy;
}

@:enum
abstract SameLinePolicy(String) {
	var Same = "same";
	var Next = "next";
}
