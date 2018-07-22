package formatter.config;

typedef IndentationConfig = {
	@:default(Aligned) @:optional var conditionalPolicy:ConditionalIndentationPolicy;
	/**
		use "tab" or "<amount of spaces per indent in spaces>" to define which character to use
	**/
	@:default("tab") @:optional var character:String;
	/**
		if `character` is set to "tab", formatter uses `tabWidth` to calculate absolute line length
	**/
	@:default(4) @:optional var tabWidth:Int;
}

@:enum
abstract ConditionalIndentationPolicy(String) {
	var FixedZero = "fixedZero";
	var Aligned = "aligned";
	var AlignedIncrease = "alignedIncrease";
}
