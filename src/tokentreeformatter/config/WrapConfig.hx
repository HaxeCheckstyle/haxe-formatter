package tokentreeformatter.config;

typedef WrapConfig = {
	@:optional var maxLineLength:Int;
	@:optional var wrapAfterComma:Bool;
	@:optional var wrapBeforeDot:Bool;
	@:optional var wrapAfterBrOpen:Bool;
	@:optional var wrapAfterBkOpen:Bool;
}