package formatter.config;

typedef WrapConfig = {
	/**
		maximum characters per line, formatter will try to wrap code longer than `maxLineLength`
	**/
	@:default(160) @:optional var maxLineLength:Int;
	/**
		should wrapping happen after comma
	**/
	@:default(true) @:optional var wrapAfterComma:Bool;
	/**
		should wrapping happen before dot
	**/
	@:default(true) @:optional var wrapBeforeDot:Bool;
	/**
		should wrapping happen after opening braces `(`
	**/
	@:default(true) @:optional var wrapAfterOpeningParenthesis:Bool;
	/**
		should wrapping happen after opening braces `{`
	**/
	@:default(true) @:optional var wrapAfterOpeningBrace:Bool;
	/**
		should wrapping happen after opening brackets `[`
	**/
	@:default(true) @:optional var wrapAfterOpeningBracket:Bool;
	@:default(30) @:optional var arrayMaxInlineAtLength:Int;
	@:default(30) @:optional var arrayMaxItemLength:Int;
	@:default(2) @:optional var arrayMaxOneLineItems:Int;
	@:default(60) @:optional var arrayTotalItemLengthOneLine:Int;
}
