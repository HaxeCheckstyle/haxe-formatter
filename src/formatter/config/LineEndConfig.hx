package formatter.config;

typedef LineEndConfig = {
	@:default(None) @:optional var metadataType:AtLineEndPolicy;
	@:default(None) @:optional var metadataVar:AtLineEndPolicy;
	@:default(None) @:optional var metadataFunction:AtLineEndPolicy;
	@:default(None) @:optional var metadataOther:AtLineEndPolicy;
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
	var ForceAfterLast = "forceAfterLast";
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
