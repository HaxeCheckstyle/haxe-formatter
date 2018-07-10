package tokentreeformatter.config;

typedef LineEndConfig = {
	@:default(tokentreeformatter.config.LineEndConfig.AtLineEndPolicy.AFTER) @:optional var at:AtLineEndPolicy;
	@:default(tokentreeformatter.config.LineEndConfig.CaseDblDotLineEndPolicy.AFTER) @:optional var caseDblDot:CaseDblDotLineEndPolicy;
	@:default(tokentreeformatter.config.LineEndConfig.SharpLineEndPolicy.AFTER) @:optional var sharp:SharpLineEndPolicy;
	@:default(tokentreeformatter.config.LineEndConfig.LeftCurlyLineEndPolicy.AFTER) @:optional var leftCurly:LeftCurlyLineEndPolicy;
	@:default(tokentreeformatter.config.LineEndConfig.RightCurlyLineEndPolicy.BOTH) @:optional var rightCurly:RightCurlyLineEndPolicy;
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