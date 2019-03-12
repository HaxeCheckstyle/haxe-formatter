import haxe.Json;
import sys.io.File;
import formatter.config.FormatterConfig;
import json2object.utils.JsonSchemaWriter;

class SchemaGenerator {
	static function main() {
		var schema = new JsonSchemaWriter<FormatterConfig>().schema;
		schema = Json.stringify(Json.parse(schema), "\t");
		File.saveContent("resources/hxformat-schema.json", schema);
	}
}
