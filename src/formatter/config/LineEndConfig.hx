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

	/**
		line end settings for block curlies
	**/
	@:default(auto) @:optional var blockCurly:CurlyLineEndPolicy;

	/**
		line end settings for anon type curlies
	**/
	@:default(auto) @:optional var anonTypeCurly:CurlyLineEndPolicy;

	/**
		line end settings for object literal curlies
	**/
	@:default(auto) @:optional var objectLiteralCurly:CurlyLineEndPolicy;

	/**
		line end settings for typedef curlies
	**/
	@:default(auto) @:optional var typedefCurly:CurlyLineEndPolicy;
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

typedef CurlyLineEndPolicy = {
	/**
		use lineEnds.leftCurly, lineEnds.rightCurly and lineEnds.emptyCurly if true
	**/
	@:default(true) @:optional var useGlobal:Bool;

	/**
		line end options for left curly
	**/
	@:default(After) @:optional var leftCurly:LeftCurlyLineEndPolicy;

	/**
		line end options for right curly
	**/
	@:default(Both) @:optional var rightCurly:RightCurlyLineEndPolicy;

	/**
		line end options for empty curlies
	**/
	@:default(NoBreak) @:optional var emptyCurly:EmptyCurlyPolicy;
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
