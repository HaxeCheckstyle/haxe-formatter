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
	@:default(auto) @:optional var enumAbstractEmptyLines:EnumAbstractFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var classEmptyLines:ClassFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var externClassEmptyLines:InterfaceFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var abstractEmptyLines:ClassFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var interfaceEmptyLines:InterfaceFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var conditionalsEmptyLines:ConditionalEmtpyLinesConfig;
}

typedef ConditionalEmtpyLinesConfig = {
	@:default(0) @:optional var afterIf:Int;
	@:default(0) @:optional var beforeElse:Int;
	@:default(0) @:optional var afterElse:Int;
	@:default(0) @:optional var beforeEnd:Int;
	@:default(0) @:optional var beforeError:Int;
	@:default(0) @:optional var afterError:Int;
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

typedef EnumAbstractFieldsEmtpyLinesConfig = {
	@:default(0) @:optional var beginType:Int;
	@:default(0) @:optional var betweenVars:Int;
	@:default(1) @:optional var afterVars:Int;
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
