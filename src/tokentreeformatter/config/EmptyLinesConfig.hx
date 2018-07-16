package tokentreeformatter.config;

typedef EmptyLinesConfig = {
	@:default(false) @:optional var finalNewline:Bool;
	@:default(1) @:optional var maxAnywhereInFile:Int;
	@:default(1) @:optional var afterPackage:Int;
	@:default(1) @:optional var beforeUsing:Int;
	@:default(1) @:optional var afterImportsUsing:Int;
	@:default(1) @:optional var betweenTypes:Int;
	@:default(0) @:optional var beforeRightCurly:Int;
	@:default(0) @:optional var beginEnumAbstract:Int;
	@:default(0) @:optional var betweenEnumAbstractVars:Int;
	@:default(1) @:optional var afterEnumAbstractVars:Int;
	@:default(1) @:optional var betweenEnumAbstractFunctions:Int;
	@:default(auto) @:optional var classEmptyLines:ClassFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var abstractEmptyLines:ClassFieldsEmtpyLinesConfig;
}

typedef ClassFieldsEmtpyLinesConfig = {
	@:default(0) @:optional var beginType:Int;
	@:default(0) @:optional var betweenStaticVars:Int;
	@:default(1) @:optional var afterStaticVars:Int;
	@:default(1) @:optional var afterPrivateVars:Int;
	@:default(0) @:optional var betweenVars:Int;
	@:default(1) @:optional var afterVars:Int;
	@:default(1) @:optional var afterStaticFunctions:Int;
	@:default(1) @:optional var betweenStaticFunctions:Int;
	@:default(1) @:optional var afterPrivateFunctions:Int;
	@:default(1) @:optional var betweenFunctions:Int;
}