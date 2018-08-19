package formatter.config;

typedef EmptyLinesConfig = {
	/**
		adds a final newline
	**/
	@:default(true) @:optional var finalNewline:Bool;

	/**
		maximum consecutive empty lines anywhere in file - runs last, all empty lines policies are limited to "maxAnywhereInFile"
	**/
	@:default(1) @:optional var maxAnywhereInFile:Int;

	/**
		empty lines after package
	**/
	@:default(1) @:optional var afterPackage:Int;
	@:default(1) @:optional var beforeUsing:Int;
	@:default(1) @:optional var afterImportsUsing:Int;

	/**
		empty lines between types
	**/
	@:default(1) @:optional var betweenTypes:Int;

	/**
		Remove or keep empty lines above "}"
	**/
	@:default(Remove) @:optional var beforeRightCurly:KeepEmptyLinesPolicy;

	/**
		Remove or keep empty lines below "{"
	**/
	@:default(Remove) @:optional var afterLeftCurly:KeepEmptyLinesPolicy;

	/**
		Remove or keep empty lines below "return"
	**/
	@:default(Remove) @:optional var afterReturn:KeepEmptyLinesPolicy;
	@:default(Remove) @:optional var beforeBlocks:KeepEmptyLinesPolicy;
	@:default(Remove) @:optional var afterBlocks:KeepEmptyLinesPolicy;
	@:default(auto) @:optional var enumAbstractEmptyLines:EnumAbstractFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var classEmptyLines:ClassFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var externClassEmptyLines:InterfaceFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var abstractEmptyLines:ClassFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var interfaceEmptyLines:InterfaceFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var enumEmptyLines:TypedefFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var typedefEmptyLines:TypedefFieldsEmtpyLinesConfig;
	@:default(auto) @:optional var conditionalsEmptyLines:ConditionalEmtpyLinesConfig;

	/**
		"one" adds one empty line above doc comments
		"none" removes all empty lines above doc comments
		"ignore" respects empty lines set via "betweenVars", "betweenFunctions", etc.
	**/
	@:default(One) @:optional var beforeDocCommentEmptyLines:CommentEmptyLinesPolicy;
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

typedef TypedefFieldsEmtpyLinesConfig = {
	@:default(0) @:optional var beginType:Int;
	@:default(0) @:optional var betweenFields:Int;
}

@:enum
abstract KeepEmptyLinesPolicy(String) {
	var Keep = "keep";
	var Remove = "remove";
}

@:enum
abstract CommentEmptyLinesPolicy(String) {
	var Ignore = "ignore";
	var None = "none";
	var One = "one";
}
