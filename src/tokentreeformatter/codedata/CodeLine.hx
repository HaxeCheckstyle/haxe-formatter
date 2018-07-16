package tokentreeformatter.codedata;

import tokentreeformatter.config.WrapConfig;
import tokentreeformatter.marker.Indenter;

class CodeLine {
	var parts:Array<CodePart>;
	var currentPart:CodePart;

	public var indent:Int;
	public var emptyLinesAfter:Int;

	public function new(indent:Int) {
		this.indent = indent;
		parts = [];
		emptyLinesAfter = 0;
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

	public function applyWrapping(config:WrapConfig, indenter:Indenter):Array<CodeLine> {
		var lineLength:Int = indent;
		for (part in parts) {
			lineLength += part.text.length;
			if (lineLength > config.maxLineLength) {
				return wrappedAt(part, config, indenter);
			}
		}
		return [this];
	}

	function wrappedAt(part:CodePart, config:WrapConfig, indenter:Indenter):Array<CodeLine> {
		// var parent:TokenTree = part.firstToken.parent;
		// switch (parent.tok) {
		// case BrOpen:
		// if (config.wrapAfterBrOpen) {
		// return wrapObject(part, config);
		// }
		// case Const(_):
		// switch (parent.parent.tok) {
		// case BkOpen:
		// if (config.wrapAfterBkOpen) {
		// return wrapArray(part, config);
		// }
		// default:
		// }
		// default:
		// }
		return wrapNormal(config, indenter);
	}

	function wrapNormal(config:WrapConfig, indenter:Indenter):Array<CodeLine> {
		if (parts.length <= 0) {
			return [this];
		}
		var line:CodeLine = new CodeLine(indent);
		var part:CodePart = parts.shift();
		line.parts = [part];
		var lineLength:Int = indent + part.text.length;
		var lines:Array<CodeLine> = [line];
		while (parts.length > 0) {
			var p:CodePart = parts.shift();
			if (lineLength + p.text.length > config.maxLineLength) {
				var newIndent:Int = indenter.calcIndent(p.firstToken);
				line = new CodeLine(newIndent);
				lineLength = newIndent;
				lines.push(line);
			}
			line.parts.push(p);
			lineLength += p.text.length;
		}
		line.emptyLinesAfter = emptyLinesAfter;
		return lines;
	}

	// function wrapObject(part:CodePart, config:WrapConfig):Array<CodeLine> {
	// return [this];
	// }
	// function wrapArray(part:CodePart, config:WrapConfig):Array<CodeLine> {
	// return [this];
	// }
	public function print(indenter:Indenter):String {
		var line:String = "";
		for (part in parts) {
			line += part.text;
		}
		line = indenter.makeIndentString(indent) + StringTools.trim(line);
		for (index in 0...emptyLinesAfter) {
			line += "\n";
		}
		return line;
	}
}

typedef CodePart = {
	var firstToken:TokenTree;
	var lastToken:TokenTree;
	var text:String;
}