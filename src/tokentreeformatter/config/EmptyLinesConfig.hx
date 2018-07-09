package tokentreeformatter.config;

typedef EmptyLinesConfig = {
	@:optional var afterPackage:Int;
	@:optional var afterImportsUsing:Int;
	@:optional var betweenTypes:Int;
	@:optional var anywhereInFileMax:Int;
	@:optional var betweenClassStaticVars:Int;
	@:optional var afterClassStaticVars:Int;
	@:optional var afterClassPrivateVars:Int;
	@:optional var betweenClassVars:Int;
	@:optional var afterClassVars:Int;
	@:optional var afterClassStaticFunctions:Int;
	@:optional var betweenClassStaticFunctions:Int;
	@:optional var afterClassPrivateFunctions:Int;
	@:optional var betweenClassFunctions:Int;
}