package tokentreeformatter.config;

typedef LineEndConfig = {
	@:default(AFTER) @:optional var atType:AtLineEndPolicy;
	@:default(NONE) @:optional var atVar:AtLineEndPolicy;
	@:default(AFTER) @:optional var atFunction:AtLineEndPolicy;
	@:default(NONE) @:optional var atOther:AtLineEndPolicy;
	@:default(AFTER) @:optional var caseDblDot:CaseDblDotLineEndPolicy;
	@:default(AFTER) @:optional var sharp:SharpLineEndPolicy;
	@:default(AFTER) @:optional var leftCurly:LeftCurlyLineEndPolicy;
	@:default(BOTH) @:optional var rightCurly:RightCurlyLineEndPolicy;
	@:default(NO_BREAK) @:optional var emptyCurly:EmptyCurlyPolicy;
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

@:enum
abstract EmptyCurlyPolicy(String) {
	var NO_BREAK = "noBreak";
	var BREAK = "break";
}