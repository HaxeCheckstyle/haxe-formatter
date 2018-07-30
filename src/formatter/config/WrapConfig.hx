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
	@:default(true) @:optional var wrapAfterPlus:Bool;

	/**
		should wrapping happen after opening brackets `[`
	**/
	@:default(true) @:optional var wrapAfterOpeningBracket:Bool;
	@:default(auto) @:optional var arrayWrap:ArrayWrapping;
	@:default(auto) @:optional var anonType:AnonTypeWrapping;
	@:default(auto) @:optional var objectLiteral:ObjectLiteralWrapping;
}

typedef ArrayWrapping = {
	@:default(30) @:optional var maxInlineAtLength:Int;
	@:default(30) @:optional var maxItemLength:Int;
	@:default(2) @:optional var maxOneLineItems:Int;
	@:default(60) @:optional var totalItemLengthOneLine:Int;
}

typedef AnonTypeWrapping = {
	@:default(30) @:optional var maxItemLength:Int;
	@:default(3) @:optional var maxOneLineItems:Int;
	@:default(60) @:optional var totalItemLengthOneLine:Int;
}

typedef ObjectLiteralWrapping = {
	@:default(30) @:optional var maxItemLength:Int;
	@:default(3) @:optional var maxOneLineItems:Int;
	@:default(60) @:optional var totalItemLengthOneLine:Int;
}
