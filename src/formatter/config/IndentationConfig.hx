package formatter.config;

typedef IndentationConfig = {
	/**
		only applies to non inlined conditionals
		"fixedZero" = all conditional statements should start in column 1
		"aligned" = conditional statements share indentation of surrounding code
		"alignedIncrease" = same as "aligned" but will increase indent by +1 for enclosed code
	**/
	@:default(Aligned) @:optional var conditionalPolicy:ConditionalIndentationPolicy;

	/**
		use "tab" or "<amount of spaces per indent in spaces>" to define which character to use
	**/
	@:default("tab") @:optional var character:String;

	/**
		if `character` is set to "tab", formatter uses `tabWidth` to calculate absolute line length
	**/
	@:default(4) @:optional var tabWidth:Int;

	/**
		adds trailing whitespace to empty lines by copying indentation from preceeding line
	**/
	@:default(false) @:optional var trailingWhitespace:Bool;
}

@:enum
abstract ConditionalIndentationPolicy(String) {
	var FixedZero = "fixedZero";
	var Aligned = "aligned";
	var AlignedIncrease = "alignedIncrease";
	var AlignedDecrease = "alignedDecrease";
}
