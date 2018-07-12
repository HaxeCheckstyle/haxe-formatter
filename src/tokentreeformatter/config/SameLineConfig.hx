package tokentreeformatter.config;

typedef SameLineConfig = {
	@:default(NEXT) @:optional var ifBody:SameLinePolicy;
	@:default(NEXT) @:optional var elseBody:SameLinePolicy;
	@:default(NEXT) @:optional var forBody:SameLinePolicy;
	@:default(NEXT) @:optional var whileBody:SameLinePolicy;
	@:default(NEXT) @:optional var doWhileBody:SameLinePolicy;
	@:default(NEXT) @:optional var anonObjects:SameLinePolicy;
}

@:enum
abstract SameLinePolicy(String) {
	var SAME = "same";
	var NEXT = "next";
}