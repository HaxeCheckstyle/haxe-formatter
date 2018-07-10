package tokentreeformatter.config;

typedef LineEndConfig = {
	@:default(AFTER) @:optional var at:AtLineEndPolicy;
	@:default(AFTER) @:optional var caseDblDot:CaseDblDotLineEndPolicy;
	@:default(AFTER) @:optional var sharp:SharpLineEndPolicy;
	@:default(AFTER) @:optional var leftCurly:LeftCurlyLineEndPolicy;
	@:default(BOTH) @:optional var rightCurly:RightCurlyLineEndPolicy;
}

@:enum
abstract AtLineEndPolicy(String) {
	var NONE = "none";
	var AFTER = "after";
	var AFTER_LAST = "afterLast";
}

@:enum
abstract CaseDblDotLineEndPolicy(String) {
	var NONE = "none";
	var AFTER = "after";
}

@:enum
abstract SharpLineEndPolicy(String) {
	var NONE = "none";
	var AFTER = "after";
}

@:enum
abstract LeftCurlyLineEndPolicy(String) {
	var NONE = "none";
	var AFTER = "after";
	var BEFORE = "before";
	var BOTH = "both";
}

@:enum
abstract RightCurlyLineEndPolicy(String) {
	var NONE = "none";
	var BEFORE = "before";
	var AFTER = "after";
	var BOTH = "both";
}