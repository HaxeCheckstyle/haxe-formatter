package formatter.config;

typedef WrapConfig = {
	/**
		maximum characters per line, formatter will try to wrap code longer than `maxLineLength`
	**/
	@:default(160) @:optional var maxLineLength:Int;

	/**
		should wrapping happen after comma
	**/
	@:default(true) @:optional var wrapAfterComma:Bool;

	/**
		should wrapping happen before dot
	**/
	@:default(true) @:optional var wrapBeforeDot:Bool;

	/**
		should wrapping happen after opening braces `(`
	**/
	@:default(true) @:optional var wrapAfterOpeningParenthesis:Bool;

	/**
		should wrapping happen after opening braces `{`
	**/
	@:default(true) @:optional var wrapAfterOpeningBrace:Bool;
	@:default(true) @:optional var wrapAfterPlus:Bool;

	/**
		should wrapping happen after opening brackets `[`
	**/
	@:default(true) @:optional var wrapAfterOpeningBracket:Bool;

	/**
		function signature wrapping rules
	**/
	@:default([
		{
			conditions: [{cond: TotalItemLengthLessThan, value: 80}],
			type: NoWrap
		},
		{
			conditions: [{cond: ItemCountLargerThan, value: 10}],
			type: FillLine
		},
		{
			conditions: [{cond: AnyItemLengthLargerThan, value: 30}],
			type: OnePerLine
		},
		{
			conditions: [{cond: ItemCountLargerThan, value: 4}],
			type: OnePerLine
		}
	])
	@:optional
	var arrayWrap:Array<WrapRule>;

	/**
		function signature wrapping rules
	**/
	@:default([{
		conditions: [{cond: AnyItemLengthLargerThan, value: 30}],
		type: FillLine
	}])
	@:optional
	var typeParameter:Array<WrapRule>;

	/**
		function signature wrapping rules
	**/
	@:default([
		{
			conditions: [{cond: ItemCountLargerThan, value: 7}],
			type: FillLine
		},
		{
			conditions: [{cond: LineLengthLargerThan, value: 140}],
			type: FillLine
		}
	])
	@:optional
	var functionSignature:Array<WrapRule>;

	/**
		object literal wrapping rules
	**/
	@:default([
		{
			conditions: [{cond: ItemCountLessThan, value: 3}],
			type: NoWrap
		},
		{
			conditions: [{cond: AnyItemLengthLargerThan, value: 30}],
			type: OnePerLine
		},
		{
			conditions: [{cond: TotalItemLengthLargerThan, value: 60}],
			type: OnePerLine
		},
		{
			conditions: [{cond: ItemCountLargerThan, value: 4}],
			type: OnePerLine
		}
	])
	@:optional
	var objectLiteral:Array<WrapRule>;

	/**
		anon types wrapping rules
	**/
	@:default([
		{
			conditions: [{cond: ItemCountLessThan, value: 3}],
			type: NoWrap
		},
		{
			conditions: [{cond: AnyItemLengthLargerThan, value: 30}],
			type: OnePerLine
		},
		{
			conditions: [{cond: TotalItemLengthLargerThan, value: 60}],
			type: OnePerLine
		},
		{
			conditions: [{cond: ItemCountLargerThan, value: 4}],
			type: OnePerLine
		}
	])
	@:optional
	var anonType:Array<WrapRule>;
}

typedef WrapRule = {
	var conditions:Array<WrapCondition>;
	var type:WrappingType;
}

@:enum
abstract WrappingType(String) {
	var OnePerLine = "onePerLine";
	var OnePerLineKeep = "onePerLineKeep";
	var EqualNumber = "equalNumber";
	var FillLine = "fillLine";
	var NoWrap = "noWrap";
}

typedef WrapCondition = {
	var cond:WrapConditionType;
	@:default(1) @:optional var value:Int;
}

@:enum
abstract WrapConditionType(String) {
	var ItemCountLargerThan = "itemCount >= n";
	var ItemCountLessThan = "itemCount <= n";
	var AnyItemLengthLargerThan = "anyItemLength >= n";
	var AnyItemLengthLessThan = "anyItemLength <= n";
	var TotalItemLengthLargerThan = "totalItemLength >= n";
	var TotalItemLengthLessThan = "totalItemLength <= n";
	var LineLengthLargerThan = "lineLength >= n";
	var LineLengthLessThan = "lineLength <= n";
}

typedef ArrayWrapping = {
	@:default(30) @:optional var maxInlineAtLength:Int;
	@:default(30) @:optional var maxItemLength:Int;
	@:default(2) @:optional var maxOneLineItems:Int;
	@:default(60) @:optional var totalItemLengthOneLine:Int;
}
