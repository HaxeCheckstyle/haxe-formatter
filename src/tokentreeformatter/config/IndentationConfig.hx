package tokentreeformatter.config;

typedef IndentationConfig = {
	@:optional var conditionalPolicy:ConditionalIndentationPolicy;
	@:optional var character:String;
}

@:enum
abstract ConditionalIndentationPolicy(String) {
	var FIXED_ZERO = "fixed_zero";
	var ALIGNED = "aligned";
	var ALIGNED_INCREASE = "aligned_increase";
}