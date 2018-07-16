package tokentreeformatter.config;

typedef LineEndConfig = {
	@:default(After) @:optional var atType:AtLineEndPolicy;
	@:default(None) @:optional var atVar:AtLineEndPolicy;
	@:default(After) @:optional var atFunction:AtLineEndPolicy;
	@:default(None) @:optional var atOther:AtLineEndPolicy;
	@:default(After) @:optional var caseColon:CaseColonLineEndPolicy;
	@:default(After) @:optional var sharp:SharpLineEndPolicy;
	@:default(After) @:optional var leftCurly:LeftCurlyLineEndPolicy;
	@:default(Both) @:optional var rightCurly:RightCurlyLineEndPolicy;
	@:default(NoBreak) @:optional var emptyCurly:EmptyCurlyPolicy;
}

@:enum
abstract AtLineEndPolicy(String) {
	var None = "none";
	var After = "after";
	var AfterLast = "afterLast";
}

@:enum
abstract CaseColonLineEndPolicy(String) {
	var None = "none";
	var After = "after";
}

@:enum
abstract SharpLineEndPolicy(String) {
	var None = "none";
	var After = "after";
}

@:enum
abstract LeftCurlyLineEndPolicy(String) {
	var None = "none";
	var After = "after";
	var Before = "before";
	var Both = "both";
}

@:enum
abstract RightCurlyLineEndPolicy(String) {
	var None = "none";
	var Before = "before";
	var After = "after";
	var Both = "both";
}

@:enum
abstract EmptyCurlyPolicy(String) {
	var NoBreak = "noBreak";
	var Break = "break";
}