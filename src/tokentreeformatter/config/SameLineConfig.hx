package tokentreeformatter.config;

typedef SameLineConfig = {
	@:default(Next) @:optional var ifBody:SameLinePolicy;
	@:default(Next) @:optional var elseBody:SameLinePolicy;
	@:default(Same) @:optional var ifElse:SameLinePolicy;
	@:default(Same) @:optional var elseIf:SameLinePolicy;
	@:default(Next) @:optional var forBody:SameLinePolicy;
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
