package formatter.debug;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;

class PosInfosMacro {
	public static function clean():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		for (field in fields) {
			switch (field.kind) {
				case FFun(f):
					var lastArgument = f.args[f.args.length - 1];
					if (lastArgument != null && lastArgument.name == "pos") {
						f.args.pop();
					}
					f.expr.iter(function loop(e) {
						switch (e.expr) {
							case ECall(e, params):
								var lastParam = params[params.length - 1];
								if (lastParam.toString() == "pos") {
									params.pop();
								}
							case _:
								e.iter(loop);
						}
					});
				case _:
			}
		}
		return fields;
	}
}
