package tokentreeformatter.marker;

import tokentreeformatter.codedata.CodeLines;
import tokentreeformatter.config.EmptyLinesConfig;

class MarkEmptyLines {

	public static function markEmptyLines(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		keepExistingEmptyLines(parsedCode);

		var packs:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdPackage)], ALL);
		for (pack in packs) {
			parsedCode.tokenList.tokens[pack.index].emptyLinesAfter = config.afterPackage;
		}

		if (config.betweenTypes > 0) {
			betweenTypes(parsedCode, config.betweenTypes);
		}

		markClasses(parsedCode, config);
	}

	public static function finalRun(codeLines:CodeLines, config:EmptyLinesConfig) {
		for (line in codeLines.lines) {
			if (line.emptyLinesAfter > config.anywhereInFileMax) {
				line.emptyLinesAfter = config.anywhereInFileMax;
			}
		}
	}

	static function markClasses(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var classes:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdClass)], ALL);
		for (c in classes) {
			var functions:Array<TokenTree> = c.filter([Kwd(KwdFunction)], FIRST);
			for (index in 0...functions.length - 1) {
				parsedCode.tokenList.emptyLinesAfterSubTree(functions[index], config.betweenClassFunctions);
			}
		}
	}

	static function betweenTypes(parsedCode:ParsedCode, count:Int) {
		var types:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdAbstract), Kwd(KwdClass), Kwd(KwdEnum), Kwd(KwdInterface), Kwd(KwdTypedef)], ALL);
		for (type in types) {
			if (type.nextSibling == null) {
				continue;
			}
			parsedCode.tokenList.emptyLinesAfterSubTree(type, count);
		}
	}

	static function keepExistingEmptyLines(parsedCode:ParsedCode) {
		var funcs:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdFunction)], ALL);
		for (func in funcs) {
			var block:TokenTree = TokenTreeAccessHelper.access(func).firstChild().is(BrOpen).token;
			if (block == null) {
				block = TokenTreeAccessHelper.access(func).firstChild().firstOf(BrOpen).token;
			}
			if (block == null) {
				continue;
			}
			var fullPos:Position = block.getPos();
			var startLine:Int = parsedCode.getLinePos(fullPos.min).line;
			var endLine:Int = parsedCode.getLinePos(fullPos.max).line;

			for (emptyLine in parsedCode.emptyLines) {
				if ((startLine >= emptyLine) || (endLine <= emptyLine)) {
					continue;
				}
				var idx:LineIds = parsedCode.linesIdx[emptyLine];
				var tokenInf:TokenInfo = parsedCode.tokenList.findTokenAtOffset(idx.l);
				if (tokenInf == null) {
					continue;
				}
				tokenInf.emptyLinesAfter++;
			}
		}
	}
}