package tokentreeformatter.codedata;

import tokentreeformatter.config.WrapConfig;
import tokentreeformatter.marker.Indenter;

class VerbatimCodeLine extends CodeLine {
	var content:String;

	public function new(content:String) {
		super(0);
		this.content = content;
		verbatim = true;
	}

	override public function addToken(tokenInfo:TokenInfo) {}

	override public function applyWrapping(config:WrapConfig, indenter:Indenter):Array<CodeLine> {
		return [this];
	}

	override public function print(indenter:Indenter, lineSeparator:String):String {
		return content;
	}
}
