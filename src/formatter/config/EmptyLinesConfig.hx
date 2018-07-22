package formatter.config;

typedef EmptyLinesConfig = {
	@:default(true) @:optional var finalNewline:Bool;
	@:default(1) @:optional var maxAnywhereInFile:Int;
	@:default(1) @:optional var afterPackage:Int;
	@:default(1) @:optional var beforeUsing:Int;
	@:default(1) @:optional var afterImportsUsing:Int;
	@:default(1) @:optional var betweenTypes:Int;
	@:default(Remove) @:optional var beforeRightCurly:KeepEmptyLinesPolicy;
	@:default(Remove) @:optional var afterLeftCurly:KeepEmptyLinesPolicy;
	@:default(Remove) @:optional var afterReturn:KeepEmptyLinesPolicy;
	@:default(0) @:optional var beginEnumAbstract:Int;
	@:default(0) @:optional var betweenEnumAbstractVars:Int;
	@:default(1) @:optional var afterEnumAbstractVars:Int;
	@:default(1) @:optional var betweenEnumAbstractFunctions:Int;
	@:default(auto) @:optional var classEmptyLines:ClassFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var externClassEmptyLines:InterfaceFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var abstractEmptyLines:ClassFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var interfaceEmptyLines:InterfaceFieldsEmtpyLinesConfig;
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

typedef InterfaceFieldsEmtpyLinesConfig = {
	@:default(0) @:optional var beginType:Int;
	@:default(0) @:optional var betweenVars:Int;
	@:default(0) @:optional var afterVars:Int;
	@:default(0) @:optional var betweenFunctions:Int;
}

@:enum
abstract KeepEmptyLinesPolicy(String) {
	var Keep = "keep";
	var Remove = "remove";
}
