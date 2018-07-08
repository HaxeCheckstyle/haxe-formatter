package tokentreeformatter.config;

typedef LineEndConfig = {
	@:optional var at:AtLineEndPolicy;
	@:optional var sharp:SharpLineEndPolicy;
	@:optional var leftCurly:LeftCurlyLineEndPolicy;
	@:optional var rightCurly:RightCurlyLineEndPolicy;
}

@:enum
abstract AtLineEndPolicy(String) {
	var NONE = "none";
	var AFTER = "after";
	var AFTER_LAST = "afterLast";
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