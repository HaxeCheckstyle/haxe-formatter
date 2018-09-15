import haxe.Json;
import haxe.io.Path;
import sys.io.File;

class SchemaGenerator {
	public static function main() {
		var config = FormatterSchemaGenerator.generate("formatter.config.FormatterConfig",
			"https://raw.githubusercontent.com/HaxeCheckstyle/haxe-formatter/master/resources/formatter-schema.json");
		File.saveContent(Path.join(["resources", "formatter-schema.json"]), Json.stringify(config, "\t"));
	}
}
