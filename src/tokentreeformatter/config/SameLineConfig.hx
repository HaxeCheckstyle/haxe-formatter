package tokentreeformatter.config;

typedef SameLineConfig = {
	@:default(Same) @:optional var ifBody:SameLinePolicy;
	@:default(Same) @:optional var elseBody:SameLinePolicy;
	@:default(Same) @:optional var ifElse:SameLinePolicy;
	@:default(Same) @:optional var forBody:SameLinePolicy;
	@:default(Same) @:optional var whileBody:SameLinePolicy;
	@:default(Same) @:optional var doWhileBody:SameLinePolicy;
	@:default(Same) @:optional var tryBody:SameLinePolicy;
	@:default(Same) @:optional var catchBody:SameLinePolicy;
	@:default(Same) @:optional var tryCatch:SameLinePolicy;
	@:default(Same) @:optional var anonObjects:SameLinePolicy;
}

@:enum
abstract SameLinePolicy(String) {
	var Same = "same";
	var Next = "next";
}