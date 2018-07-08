package tokentreeformatter.marker;

import tokentreeformatter.config.IndentationConfig;

class Indenter {

	var config:IndentationConfig;
	var parsedCode:ParsedCode;

	public function new(config:IndentationConfig) {
		this.config = config;
		if (config.character.toLowerCase() == "tab") {
			config.character = "\t";
		}
	}

	public function setParsedCode (parsedCode:ParsedCode) {
		this.parsedCode = parsedCode;
	}

	public function makeIndent(token:TokenTree):String {
		return StringTools.lpad("", config.character, config.character.length * calcIndent(token));
	}

	function calcIndent(token:TokenTree):Int {
		var indent:Int = 0;
		if (token == null) {
			return 0;
		}

		switch (token.tok) {
			case BrClose, BkClose, PClose:
				// use BrOpen, BkOpen, POpen for calculation
				token = token.parent;
			case Sharp(_):
				if (config.conditionalPolicy == FIXED_ZERO) return 0;
			default:
		}

		while ((token.parent != null) && (token.parent.tok != null)) {
			token = token.parent;
			if (shouldIndent(token)) {
				indent++;
			}
		}
		return indent;
	}

	function shouldIndent(token:TokenTree):Bool {
		switch (token.tok) {
			case BrOpen, BkOpen, POpen:
				var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
				if (next == null) {
					return true;
				}
				if (shouldIndent(next.token)) {
					return false;
				}
				return true;
			case Binop(OpAssign):
				var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
				if (next == null) {
					return true;
				}
				if (shouldIndent(next.token)) {
					return false;
				}
				return true;
			case DblDot:
				if ((token.parent.is(Kwd(KwdCase))) || (token.parent.is(Kwd(KwdDefault)))) {
					return true;
				}
			case Sharp(_):
				if (config.conditionalPolicy == ALIGNED_INCREASE) {
					return true;
				}
			default:
		}
		return false;
	}
}