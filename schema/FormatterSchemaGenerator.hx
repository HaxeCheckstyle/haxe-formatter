#if macro
import haxe.DynamicAccess;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import haxe.io.Path;
import haxe.ds.ArraySort;

using StringTools;

typedef CheckName = {
	var name:String;
	var path:String;
}
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
