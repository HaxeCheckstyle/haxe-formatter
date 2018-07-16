package tokentreeformatter.config;

@:enum
abstract WhitespacePolicy(String) {
	var None = "none";
	var Before = "before";
	var NoneBefore = "noneBefore";
	var OnlyBefore = "onlyBefore";
	var After = "after";
	var OnlyAfter = "onlyAfter";
	var NoneAfter = "noneAfter";
	var Around = "around";

	public static function remove(policy:WhitespacePolicy, remove:WhitespacePolicy):WhitespacePolicy {
		switch (remove) {
			case None:
				return policy;
			case Before:
			case NoneBefore:
				remove = Before;
			case OnlyBefore:
				remove = Before;
			case After:
			case NoneAfter:
				remove = After;
			case OnlyAfter:
				remove = After;
			case Around:
				return None;
		}
		switch (policy) {
			case None:
				return None;
			case Before:
				if (remove == Before) {
					return None;
				}
			case NoneBefore:
				return NoneBefore;
			case OnlyBefore:
				if (remove == Before) {
					return None;
				}
			case After:
				if (remove == After) {
					return None;
				}
			case NoneAfter:
				return NoneAfter;
			case OnlyAfter:
				if (remove == After) {
					return None;
				}
			case Around:
				if (remove == Before) {
					return After;
				}
				if (remove == After) {
					return Before;
				}
		}
		return policy;
	}
}
