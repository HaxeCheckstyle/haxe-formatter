package tokentreeformatter.config;

typedef WrapConfig = {
	@:default(160) @:optional var maxLineLength:Int;
	@:default(true) @:optional var wrapAfterComma:Bool;
	@:default(true) @:optional var wrapBeforeDot:Bool;
	@:default(true) @:optional var wrapAfterOpeningBrace:Bool;
	@:default(true) @:optional var wrapAfterOpeningBracket:Bool;
}
