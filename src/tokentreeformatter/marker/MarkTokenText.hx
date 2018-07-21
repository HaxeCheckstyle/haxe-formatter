package tokentreeformatter.marker;

class MarkTokenText {
	public static function markTokenText(parsedCode:ParsedCode, indenter:Indenter) {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Const(CString(text)):
					parsedCode.tokenList.tokenText(token, printStringToken(token, parsedCode));
				case Const(CRegexp(_, _)):
					parsedCode.tokenList.tokenText(token, printEregToken(token, parsedCode));
				case Comment(text):
					parsedCode.tokenList.tokenText(token, printComment(text, token, parsedCode, indenter));
				case CommentLine(text):
					parsedCode.tokenList.tokenText(token, printCommentLine(text));
				default:
					parsedCode.tokenList.tokenText(token, token.toString());
			}
			return GO_DEEPER;
		});
	}

	public static function printStringToken(token:TokenTree, parsedCode:ParsedCode):String {
		return parsedCode.getString(token.pos.min, token.pos.max);
	}

	public static function printEregToken(token:TokenTree, parsedCode:ParsedCode):String {
		return parsedCode.getString(token.pos.min, token.pos.max);
	}

	public static function printComment(text:String, token:TokenTree, parsedCode:ParsedCode, indenter:Indenter):String {
		var lines:Array<String> = text.split(parsedCode.lineSeparator);
		var indent:Int = indenter.calcIndent(token);

		var lastLine:String = lines[lines.length - 1];
		var prefixReg:EReg = ~/^(\s*)/;
		var prefix:String = "";
		if (prefixReg.match(lastLine)) {
			prefix = prefixReg.matched(1);
		}
		text = "/*" + lines[0];
		for (index in 1...lines.length) {
			text += parsedCode.lineSeparator;
			var line:String = lines[index].rtrim();
			if (line.startsWith(prefix)) {
				line = line.substr(prefix.length);
			}
			var lineIndent:Int = indent;
			var lastLine:Bool = index == lines.length - 1;
			var startsWithStar:Bool = ~/^\*/.match(line);
			if (!lastLine && line.length <= 0) {
				lineIndent = 0;
			}
			if ((!lastLine && startsWithStar) || (lastLine && !startsWithStar)) {
				line = " " + line;
			}
			text += indenter.makeIndentString(lineIndent) + line;
		}
		return text + "*/";
	}

	public static function printCommentLine(text:String):String {
		if (~/^[A-Za-z0-9]+/.match(text)) {
			return "// " + text.trim();
		}
		return "//" + text.rtrim();
	}
}
