package tokentreeformatter.config;

typedef IndentationConfig = {
	@:default(ALIGNED) @:optional var conditionalPolicy:ConditionalIndentationPolicy;
	@:default("tab") @:optional var character:String;
}

@:enum
abstract ConditionalIndentationPolicy(String) {
	var FIXED_ZERO = "fixed_zero";
	var ALIGNED = "aligned";
	var ALIGNED_INCREASE = "aligned_increase";
}