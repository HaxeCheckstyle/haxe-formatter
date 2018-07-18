package tokentreeformatter.config;

typedef IndentationConfig = {
	@:default(Aligned) @:optional var conditionalPolicy:ConditionalIndentationPolicy;
	/**
		use "tab" or "<amount of spaces per indent in spaces>" to define which character to use
	**/
	@:default("tab") @:optional var character:String;
}

@:enum
abstract ConditionalIndentationPolicy(String) {
	var FixedZero = "fixedZero";
	var Aligned = "aligned";
	var AlignedIncrease = "alignedIncrease";
}
