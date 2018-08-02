package formatter.codedata;

import formatter.config.WrapConfig;
import formatter.marker.Indenter;

class CodeLine {
	var parts:Array<CodePart>;
	var currentPart:CodePart;

	public var indent:Int;
	public var emptyLinesAfter:Int;
	public var verbatim:Bool;

	public function new(indent:Int) {
		this.indent = indent;
		parts = [];
		emptyLinesAfter = 0;
		verbatim = false;
	}

	public function addToken(tokenInfo:TokenInfo) {
		if (tokenInfo.emptyLinesAfter > emptyLinesAfter) {
			emptyLinesAfter = tokenInfo.emptyLinesAfter;
		}
		if (currentPart == null) {
			currentPart = {firstToken: tokenInfo.token, lastToken: tokenInfo.token, text: ""};
			parts.push(currentPart);
		}
		currentPart.lastToken = tokenInfo.token;
		if (tokenInfo.whitespaceAfter == Space) {
			currentPart.text += tokenInfo.text + " ";
		} else {
			currentPart.text += tokenInfo.text;
		}
		if (tokenInfo.wrapAfter) {
			currentPart = null;
		}
	}

	public function applyWrapping(config:WrapConfig, parsedCode:ParsedCode, indenter:Indenter):Array<CodeLine> {
		var lineLength:Int = indent;
		for (index in 0...parts.length) {
			var part:CodePart = parts[index];
			lineLength += part.text.length;
			if (lineLength > config.maxLineLength) {
				return wrappedAt(index, config, parsedCode, indenter);
			}
		}
		return [this];
	}

	function wrappedAt(index:Int, config:WrapConfig, parsedCode:ParsedCode, indenter:Indenter):Array<CodeLine> {
		// while (index >= 0) {
		// 	var current:CodePart = parts[index];
		// 	if (current.lastToken.is(BkOpen)) {
		// 		return wrapArray(index, config, indenter);
		// 	}
		// 	// if (current.lastToken.is(BrOpen)) {
		// 	// 	return wrapObject(index);
		// 	// }
		// 	index--;
		// }
		// var parent:TokenTree = part.firstToken.parent;
		// switch (parent.tok) {
		// case BrOpen:
		// if (config.wrapAfterOpeningBrace) {
		// return wrapObject(part, config);
		// }
		// case Const(_):
		// switch (parent.parent.tok) {
		// case BkOpen:
		// if (config.owrapAfterOpeningBracket) {
		// return wrapArray(part, config);
		// }
		// default:
		// }
		// default:
		// }
		return wrapNormal(config, parsedCode, indenter);
	}

	function wrapNormal(config:WrapConfig, parsedCode:ParsedCode, indenter:Indenter):Array<CodeLine> {
		if (parts.length <= 0) {
			return [this];
		}
		var line:CodeLine = new CodeLine(indent);
		var part:CodePart = parts.shift();
		line.parts = [part];
		var lineLength:Int = indent + part.text.length;
		var lines:Array<CodeLine> = [line];
		var lastPart:CodePart = part;
		while (parts.length > 0) {
			var p:CodePart = parts.shift();
			if (lineLength + p.text.length > config.maxLineLength) {
				parsedCode.tokenList.lineEndAfter(lastPart.lastToken);
				var newIndent:Int = indenter.calcIndent(p.firstToken);
				line = new CodeLine(newIndent);
				lineLength = newIndent;
				lines.push(line);
			}
			line.parts.push(p);
			lineLength += p.text.length;
			lastPart = p;
		}
		line.emptyLinesAfter = emptyLinesAfter;
		return lines;
	}

	// function wrapObject(part:CodePart, config:WrapConfig):Array<CodeLine> {
	// return [this];
	// }
	// function wrapArray(index:Int, config:WrapConfig, indenter:Indenter):Array<CodeLine> {
	// 	return [this];
	// }
	public function print(indenter:Indenter, lineSeparator:String):String {
		var line:String = "";
		for (part in parts) {
			line += part.text;
		}
		line = indenter.makeIndentString(indent) + line.trim();
		for (index in 0...emptyLinesAfter) {
			line += lineSeparator;
		}
		return line;
	}
}

typedef CodePart = {
	var firstToken:TokenTree;
	var lastToken:TokenTree;
	var text:String;
}
