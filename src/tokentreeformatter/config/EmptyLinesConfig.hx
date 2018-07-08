package tokentreeformatter.config;

typedef EmptyLinesConfig = {
	@:optional var afterPackage:Int;
	@:optional var afterImportsUsing:Int;
	@:optional var betweenTypes:Int;
	@:optional var anywhereInFileMax:Int;
	@:optional var betweenClassFunctions:Int;
}