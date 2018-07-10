package tokentreeformatter.config;

typedef WrapConfig = {
	@:default(160) @:optional var maxLineLength:Int;
	@:default(true) @:optional var wrapAfterComma:Bool;
	@:default(true) @:optional var wrapBeforeDot:Bool;
	@:default(true) @:optional var wrapAfterBrOpen:Bool;
	@:default(true) @:optional var wrapAfterBkOpen:Bool;
}