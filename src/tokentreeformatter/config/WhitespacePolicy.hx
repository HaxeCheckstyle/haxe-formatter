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

	public static function remove(policy:WhitespacePolicy, remove:WhitespacePolicy):WhitespacePolicy {
		switch (remove) {
			case NONE:
				return policy;
			case BEFORE:
			case NONE_BEFORE:
				remove = BEFORE;
			case ONLY_BEFORE:
				remove = BEFORE;
			case AFTER:
			case NONE_AFTER:
				remove = AFTER;
			case ONLY_AFTER:
				remove = AFTER;
			case AROUND:
				return NONE;
		}
		switch (policy) {
			case NONE:
				return NONE;
			case BEFORE:
				if (remove == BEFORE) {
					return NONE;
				}
			case NONE_BEFORE:
				return NONE_BEFORE;
			case ONLY_BEFORE:
				if (remove == BEFORE) {
					return NONE;
				}
			case AFTER:
				if (remove == AFTER) {
					return NONE;
				}
			case NONE_AFTER:
				return NONE_AFTER;
			case ONLY_AFTER:
				if (remove == AFTER) {
					return NONE;
				}
			case AROUND:
				if (remove == BEFORE) {
					return AFTER;
				}
				if (remove == AFTER) {
					return BEFORE;
				}
		}
		return policy;
	}
}