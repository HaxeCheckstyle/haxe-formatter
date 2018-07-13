package tokentreeformatter.config;

@:enum
abstract WhitespacePolicy(String) {
	var NONE = "none";
	var BEFORE = "before";
	var NONE_BEFORE = "noneBefore";
	var ONLY_BEFORE = "onlyBefore";
	var AFTER = "after";
	var ONLY_AFTER = "onlyAfter";
	var NONE_AFTER = "noneAfter";
	var AROUND = "around";
}