import haxe.Json;
import tokentreeformatter.config.Config;
import tokentreeformatter.config.FormatterConfig;
import tokentreeformatter.Formatter;

class GoldFormatter extends Formatter {
	var config:FormatterConfig;

	public function new(config:FormatterConfig) {
		super();
		this.config = config;
	}

	override function loadConfig(fileName:String):Config {
		if (config == null) {
			return super.loadConfig(fileName);
		}
		var defaultConfig:Config = new Config();
		defaultConfig.readConfigFromString(Json.stringify(config), "goldhxformat.json");
		return defaultConfig;
	}
}