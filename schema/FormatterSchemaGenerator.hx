#if macro
import haxe.DynamicAccess;
import haxe.macro.Expr;
#end

class FormatterSchemaGenerator {
	macro public static function generate(type:String, id:String):Expr {
		return JsonSchemaGenerator.generateWithCallback(type, id, formatterFieldsCallback);
	}

	#if macro
	static function formatterFieldsCallback(fields:Array<ObjectDeclField>, name:String, pos:Position, refs:DynamicAccess<Expr>):Void {
		switch (name) {
			default:
		}
	}
	#end
}
