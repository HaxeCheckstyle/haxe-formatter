package tokentreeformatter.marker;

class MarkTokenText {
	public static function markTokenText(parsedCode:ParsedCode, indenter:Indenter) {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Const(CString(text)):
					parsedCode.tokenList.tokenText(token, printStringToken(token, parsedCode));
				case Comment(text):
					parsedCode.tokenList.tokenText(token, printComment(text, token, parsedCode, indenter));
				default:
					parsedCode.tokenList.tokenText(token, token.toString());
			}
			return GO_DEEPER;
		});
	}

	public static function printStringToken(token:TokenTree, parsedCode:ParsedCode):String {
		return parsedCode.getString(token.pos.min, token.pos.max);
	}

	public static function printComment(text:String, token:TokenTree, parsedCode:ParsedCode, indenter:Indenter):String {
		var lines:Array<String> = text.split(parsedCode.lineSeparator);
		text = "/*" + lines[0];
		for (index in 1...lines.length) {
			text += parsedCode.lineSeparator;
			var line:String = StringTools.rtrim(lines[index]);
			if (~/^\s*\*/.match(line)) {
				line = " " + StringTools.ltrim(line);
			}
			text += indenter.makeIndent(token) + line;
		}
		return text + "*/";
	}
}