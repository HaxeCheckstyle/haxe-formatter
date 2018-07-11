package tokentreeformatter.config;

@:enum
abstract WhitespacePolicy(String) {
	var NONE = "none";
	var NONE_AFTER = "noneAfter";
	var ONLY_AFTER = "onlyAfter";
	var BEFORE = "before";
	var AFTER = "after";
	var AROUND = "around";
}