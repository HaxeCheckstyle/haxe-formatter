package tokentreeformatter.config;

typedef EmptyLinesConfig = {
	@:default(1) @:optional var afterPackage:Int;
	@:default(1) @:optional var afterImportsUsing:Int;
	@:default(1) @:optional var betweenTypes:Int;
	@:default(1) @:optional var anywhereInFileMax:Int;
	@:default(1) @:optional var betweenClassStaticVars:Int;
	@:default(1) @:optional var afterClassStaticVars:Int;
	@:default(1) @:optional var afterClassPrivateVars:Int;
	@:default(0) @:optional var betweenClassVars:Int;
	@:default(1) @:optional var afterClassVars:Int;
	@:default(1) @:optional var afterClassStaticFunctions:Int;
	@:default(0) @:optional var betweenClassStaticFunctions:Int;
	@:default(1) @:optional var afterClassPrivateFunctions:Int;
	@:default(1) @:optional var betweenClassFunctions:Int;
}