package formatter.marker;

import haxeparser.HaxeLexer;
import tokentree.TokenStreamProgress;
import tokentree.walk.WalkStatement;
import tokentree.TokenStream;
import formatter.config.Config;
import formatter.config.IndentationConfig;
import formatter.codedata.CodeLines;
import formatter.codedata.ParseFile;
import formatter.codedata.ParsedCode;
import formatter.codedata.TokenData;

class MarkTokenText {
	public static function markTokenText(parsedCode:ParsedCode, indenter:Indenter, config:Config) {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Const(CString(text)):
					parsedCode.tokenList.tokenText(token, printStringToken(token, parsedCode, config));
				case Const(CRegexp(_, _)):
					parsedCode.tokenList.tokenText(token, printEregToken(token, parsedCode));
				case CommentLine(text):
					parsedCode.tokenList.tokenText(token, printCommentLine(text));
				default:
					parsedCode.tokenList.tokenText(token, token.toString());
			}
			return GO_DEEPER;
		});
	}

	public static function finalRun(parsedCode:ParsedCode, indenter:Indenter, config:IndentationConfig) {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Comment(text):
					parsedCode.tokenList.tokenText(token, printComment(text, token, parsedCode, indenter, config));
				default:
			}
			return GO_DEEPER;
		});
	}

	public static function printStringToken(token:TokenTree, parsedCode:ParsedCode, config:Config):String {
		var text:String = parsedCode.getString(token.pos.min, token.pos.max);
		if (!config.whitespace.formatStringInterpolation) {
			return text;
		}
		if (text.startsWith("'")) {
			var start:Int = 0;
			var index:Int;
			while ((index = text.indexOf("${", start)) >= 0) {
				if (isDollarEscaped(text, index)) {
					return text;
				}
				start = index + 1;
				var indexEnd:Int = text.indexOf("}", index + 2);
				var fragment:String = text.substring(index + 2, indexEnd);
				if (fragment.indexOf("{") >= 0) {
					continue;
				}
				var formatted:String = formatFragment(fragment, config);
				start += formatted.length - fragment.length;
				text = text.substr(0, index + 2) + formatted + text.substr(indexEnd);
			}
		}
		return text;
	}

	static function isDollarEscaped(text:String, index:Int):Bool {
		var escaped:Bool = false;
		while (--index >= 0) {
			if (text.fastCodeAt(index) != "$".code) {
				return escaped;
			}
			escaped = !escaped;
		}
		return escaped;
	}

	static function formatFragment(fragment:String, config:Config):String {
		try {
			var file:ParseFile = {
				name: "string interpolation",
				content: cast ByteData.ofString(fragment)
			};
			var tokens:Array<Token> = makeTokens(ByteData.ofString(fragment), file.name);
			var stream:TokenStream = new TokenStream(tokens, ByteData.ofString(fragment));
			var root:TokenTree = new TokenTree(null, "", null, -1);
			var progress:TokenStreamProgress = new TokenStreamProgress(stream);
			while (progress.streamHasChanged()) {
				if (stream.hasMore()) {
					WalkStatement.walkStatement(stream, root);
				}
			}
			var tokenData:TokenData = {
				tokens: tokens,
				tokenTree: root
			};
			var parsedCode:ParsedCode = new ParsedCode(file, tokenData);
			var indenter = new Indenter(config.indentation);
			indenter.setParsedCode(parsedCode);
			MarkTokenText.markTokenText(parsedCode, indenter, config);
			MarkWhitespace.markWhitespace(parsedCode, config.whitespace);
			var lines:CodeLines = new CodeLines(parsedCode, indenter);
			var formatted:String = lines.print(parsedCode.lineSeparator);
			return formatted.trim();
		} catch (e:Any) {
			// ignore any errors
		}
		return fragment;
	}

	static function makeTokens(fragment:ByteData, name:String):Array<Token> {
		var tokens:Array<Token> = [];
		try {
			var lexer = new HaxeLexer(fragment, name);
			var t:Token = lexer.token(haxeparser.HaxeLexer.tok);

			while (t.tok != Eof) {
				tokens.push(t);
				t = lexer.token(haxeparser.HaxeLexer.tok);
			}
		} catch (e:Any) {
			throw 'failed to make tokens $e';
		}
		return tokens;
	}

	public static function printEregToken(token:TokenTree, parsedCode:ParsedCode):String {
		return parsedCode.getString(token.pos.min, token.pos.max);
	}

	public static function printComment(text:String, token:TokenTree, parsedCode:ParsedCode, indenter:Indenter, config:IndentationConfig):String {
		var lines:Array<String> = text.split(parsedCode.lineSeparator);
		var indent:Int = indenter.calcIndent(token);

		var linesNew:Array<String> = [];
		for (line in lines) {
			linesNew.push(convertLeadingIndent(line, config));
		}
		lines = removeCommentPrefix(linesNew);

		text = "/*" + lines[0];
		for (index in 1...lines.length) {
			text += parsedCode.lineSeparator;
			var line:String = lines[index].rtrim();
			var lineIndent:Int = indent;
			var lastLine:Bool = index == lines.length - 1;
			var startsWithStar:Bool = ~/^\*/.match(line);
			if (!lastLine) {
				lineIndent++;
			}
			if (startsWithStar) {
				lineIndent = indent;
			}
			if (!lastLine && line.length <= 0) {
				lineIndent = 0;
			}
			if (!lastLine && startsWithStar) {
				line = " " + line;
			}
			if (lastLine) {
				if (~/^\s*$/.match(line)) {
					line = " ";
				}
				if (~/[^*\s]/.match(line)) {
					lineIndent = indent + 1;
					line = line.rtrim() + " ";
				}
			}
			text += indenter.makeIndentString(lineIndent) + line;
		}
		return text + "*/";
	}

	static function removeCommentPrefix(lines:Array<String>):Array<String> {
		var prefixReg:EReg = ~/^(\s*)/;
		var prefix:String = null;
		var linesNew:Array<String> = [];
		for (index in 1...lines.length - 1) {
			var line:String = lines[index];
			if (prefixReg.match(line)) {
				var linePrefix:String = prefixReg.matched(1);
				if (linePrefix.length <= 0) {
					continue;
				}
				if ((prefix == null) || (prefix.length > linePrefix.length)) {
					prefix = linePrefix;
				}
			}
		}
		if (prefix != null) {
			linesNew = [];
			for (line in lines) {
				if (line.startsWith(prefix)) {
					line = line.substr(prefix.length);
				}
				linesNew.push(line);
			}
			lines = linesNew;
		}
		var lastLine:String = lines[lines.length - 1];
		if (~/^\s*\*?$/.match(lastLine)) {
			lines[lines.length - 1] = lastLine.ltrim();
		}
		return lines;
	}

	static function convertLeadingIndent(line:String, config:IndentationConfig):String {
		var spaceIndent:String = "".lpad(" ", config.tabWidth);
		var oneIndent:String = config.character;
		var whitespaceReg:EReg = ~/^\s+/;
		if (!whitespaceReg.match(line)) {
			return line;
		}
		var match:String = whitespaceReg.matched(0);
		if (config.character == "\t") {
			var newPrefix:String = match.replace(spaceIndent, oneIndent);
			line = newPrefix + line.substr(match.length);
		} else {
			var newPrefix:String = match.replace("\t", oneIndent);
			line = newPrefix + line.substr(match.length);
		}
		return line;
	}

	public static function printCommentLine(text:String):String {
		if (~/^[A-Za-z0-9]+/.match(text)) {
			return "// " + text.trim();
		}
		return "//" + text.rtrim();
	}
}
