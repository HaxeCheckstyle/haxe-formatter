package tokentreeformatter.config;

typedef SameLineConfig = {
	@:default(SAME) @:optional var ifBody:SameLinePolicy;
	@:default(SAME) @:optional var elseBody:SameLinePolicy;
	@:default(SAME) @:optional var forBody:SameLinePolicy;
	@:default(SAME) @:optional var whileBody:SameLinePolicy;
	@:default(SAME) @:optional var doWhileBody:SameLinePolicy;
	@:default(SAME) @:optional var anonObjects:SameLinePolicy;
}

@:enum
abstract SameLinePolicy(String) {
	var SAME = "same";
	var NEXT = "next";
}