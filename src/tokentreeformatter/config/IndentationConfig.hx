package tokentreeformatter.config;

typedef IndentationConfig = {
	@:default(Aligned) @:optional var conditionalPolicy:ConditionalIndentationPolicy;
	@:default("tab") @:optional var character:String;
}

@:enum
abstract ConditionalIndentationPolicy(String) {
	var FixedZero = "fixedZero";
	var Aligned = "aligned";
	var AlignedIncrease = "alignedIncrease";
}
