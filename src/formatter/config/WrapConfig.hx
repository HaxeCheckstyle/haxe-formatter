package formatter.config;

typedef WrapConfig = {
	/**
		maximum characters per line, formatter will try to wrap code longer than `maxLineLength`
	**/
	@:default(160) @:optional var maxLineLength:Int;

	/**
		array wrapping rules
		does not affect array comprehension, use "sameLine.comprehensionFor"
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
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
		]
	})
	@:optional
	var arrayWrap:WrapRules;

	/**
		type parameter wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [{cond: AnyItemLengthLargerThan, value: 50}],
				type: FillLine
			},
			{
				conditions: [{cond: TotalItemLengthLargerThan, value: 70}],
				type: FillLine
			}
		]
	})
	@:optional
	var typeParameter:WrapRules;

	/**
		named function signature wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [{cond: ItemCountLargerThan, value: 7}],
				type: FillLine,
				additionalIndent: 1
			},
			{
				conditions: [{cond: TotalItemLengthLargerThan, value: 100}],
				type: FillLine,
				additionalIndent: 1
			},
			{
				conditions: [{cond: LineLengthLargerThan, value: 160}],
				type: FillLine,
				additionalIndent: 1
			}
		]
	})
	@:optional
	var functionSignature:WrapRules;

	/**
		anon function signature wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [{cond: ItemCountLargerThan, value: 7}],
				type: FillLine,
				additionalIndent: 1
			},
			{
				conditions: [{cond: TotalItemLengthLargerThan, value: 80}],
				type: FillLine,
				additionalIndent: 1
			}
		]
	})
	@:optional
	var anonFunctionSignature:WrapRules;

	/**
		call parameter wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [{cond: ItemCountLargerThan, value: 7}],
				type: FillLine
			},
			{
				conditions: [{cond: TotalItemLengthLargerThan, value: 140}],
				type: FillLine
			},
			{
				conditions: [{cond: AnyItemLengthLargerThan, value: 80}],
				type: FillLine
			}
		]
	})
	@:optional
	var callParameter:WrapRules;

	/**
		metadata call parameter wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [{cond: TotalItemLengthLargerThan, value: 140}],
				type: FillLine
			},
			{
				conditions: [{cond: LineLengthLargerThan, value: 160}],
				type: FillLine
			}
		]
	})
	@:optional
	var metadataCallParameter:WrapRules;

	/**
		object literal wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
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
		]
	})
	@:optional
	var objectLiteral:WrapRules;

	/**
		anon types wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
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
		]
	})
	@:optional
	var anonType:WrapRules;

	/**
		method chaining wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [{cond: TotalItemLengthLargerThan, value: 140}],
				type: FillLine
			},
			{
				conditions: [{cond: ItemCountLessThan, value: 3}],
				type: NoWrap
			},
			{
				conditions: [{cond: TotalItemLengthLessThan, value: 80}],
				type: NoWrap
			},
			{
				conditions: [
					{cond: AnyItemLengthLargerThan, value: 30},
					{cond: ItemCountLargerThan, value: 4}
				],
				type: OnePerLineAfterFirst
			},
			{
				conditions: [{cond: ItemCountLargerThan, value: 7}],
				type: OnePerLineAfterFirst
			}
		]
	})
	@:optional
	var methodChain:WrapRules;

	/**
		OpBool chain wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [
					{cond: LineLengthLargerThan, value: 140},
					{cond: AnyItemLengthLargerThan, value: 40}
				],
				location: BeforeLast,
				type: OnePerLineAfterFirst
			},
			{
				conditions: [{cond: LineLengthLargerThan, value: 140}],
				location: BeforeLast,
				type: FillLine
			},
			{
				conditions: [{cond: ItemCountLessThan, value: 3}],
				type: NoWrap
			},
			{
				conditions: [{cond: TotalItemLengthLessThan, value: 120}],
				type: NoWrap
			},
			{
				conditions: [{cond: ItemCountLargerThan, value: 4}],
				location: BeforeLast,
				type: OnePerLineAfterFirst
			}
		]
	})
	@:optional
	var opBoolChain:WrapRules;

	/**
		implements / extends chain wrapping rules
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [{cond: LineLengthLargerThan, value: 140}],
				type: FillLine,
				additionalIndent: 2
			},
			{
				conditions: [{cond: ItemCountLargerThan, value: 4}],
				type: FillLine,
				additionalIndent: 2
			}
		]
	})
	@:optional
	var implementsExtends:WrapRules;

	/**
		chain wrapping rules for OpAdd / OpSub
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [
					{cond: LineLengthLargerThan, value: 140},
					{cond: AnyItemLengthLargerThan, value: 60}
				],
				location: BeforeLast,
				type: OnePerLineAfterFirst
			},
			{
				conditions: [{cond: LineLengthLargerThan, value: 140}],
				location: BeforeLast,
				type: FillLine
			},
			{
				conditions: [{cond: ItemCountLessThan, value: 3}],
				type: NoWrap
			},
			{
				conditions: [{cond: TotalItemLengthLessThan, value: 120}],
				type: NoWrap
			},
			{
				conditions: [{cond: ItemCountLargerThan, value: 4}],
				location: BeforeLast,
				type: OnePerLineAfterFirst
			}
		]
	})
	@:optional
	var opAddSubChain:WrapRules;

	/**
		chain wrapping rules for OpAdd / OpSub
	**/
	@:default({
		defaultWrap: NoWrap,
		rules: [
			{
				conditions: [{cond: AnyItemLengthLessThan, value: 15}],
				type: FillLine
			},
			{
				conditions: [{cond: LineLengthLargerThan, value: 80},],
				type: OnePerLineAfterFirst
			},
		]
	})
	@:optional
	var multiVar:WrapRules;
}

typedef WrapRules = {
	/**
		list of wrapping rules
		wrapping uses only the first rule whose conditions evaluates to true
	**/
	@:default([]) @:optional var rules:Array<WrapRule>;

	/**
		default wrapping type when no rule applies
	**/
	@:default(NoWrap) @:optional var defaultWrap:WrappingType;

	/**
		default wrapping location before / after last token
	**/
	@:default(AfterLast) @:optional var defaultLocation:WrappingLocation;

	/**
		adds indentation to all wrapped lines when applying defaultWrap
	**/
	@:default(0) @:optional var defaultAdditionalIndent:Int;
}

typedef WrapRule = {
	/**
		list of conditions
		wrapping selects a rule if all of its conditions evaluate to true
	**/
	var conditions:Array<WrapCondition>;

	/**
		wrapping type
	**/
	var type:WrappingType;

	/**
		default wrapping location before / after last token
	**/
	@:default(AfterLast) @:optional var location:WrappingLocation;

	/**
		adds indentation to all wrapped lines
	**/
	@:default(0) @:optional var additionalIndent:Int;
}

@:enum
abstract WrappingType(String) {
	var OnePerLine = "onePerLine";
	var OnePerLineAfterFirst = "onePerLineAfterFirst";
	var EqualNumber = "equalNumber";
	var FillLine = "fillLine";
	var NoWrap = "noWrap";
	var Keep = "keep";
}

@:enum
abstract WrappingLocation(String) {
	var BeforeLast = "beforeLast";
	var AfterLast = "afterLast";
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
