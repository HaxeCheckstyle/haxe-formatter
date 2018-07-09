package tokentreeformatter.marker;

import tokentree.utils.FieldUtils;
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

		markImports(parsedCode, config);
		markClasses(parsedCode, config);
	}

	public static function finalRun(codeLines:CodeLines, config:EmptyLinesConfig) {
		for (line in codeLines.lines) {
			if (line.emptyLinesAfter > config.anywhereInFileMax) {
				line.emptyLinesAfter = config.anywhereInFileMax;
			}
		}
	}

	static function markImports(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var imports:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdImport), Kwd(KwdUsing)], ALL);
		if (imports.length <= 0) {
			return;
		}

		var lastImport:TokenTree = imports[imports.length - 1];
		var next:TokenTree = lastImport.nextSibling;
		if (next != null) {
			var semicolon:TokenInfo = parsedCode.tokenList.getPreviousToken(next);
			if (semicolon != null) {
				semicolon.emptyLinesAfter = config.afterImportsUsing;
			}
		}
	}

	static function markClasses(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var classes:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdClass)], ALL);
		for (c in classes) {
			var functions:Array<TokenTree> = c.filter([Kwd(KwdFunction), Kwd(KwdVar)], FIRST);

			var prevToken:TokenTree = null;
			var prevTokenType:TokenFieldType = null;
			var currToken:TokenTree = null;
			var currTokenType:TokenFieldType = null;
			for (func in functions) {
				currToken = func;
				currTokenType = FieldUtils.getFieldType(func, PRIVATE);
				makeClassFieldEmptyLines(parsedCode, prevToken, prevTokenType, currToken, currTokenType, config);
				prevToken = currToken;
				prevTokenType = currTokenType;
			}
		}
	}

	static function makeClassFieldEmptyLines(parsedCode:ParsedCode,
		prevToken:TokenTree,
		prevTokenType:TokenFieldType,
		currToken:TokenTree,
		currTokenType:TokenFieldType,
		config:EmptyLinesConfig) {
		if (prevToken == null) {
			return;
		}
		var prevVar:Bool = false;
		var currVar:Bool = false;
		var prevStatic:Bool = false;
		var currStatic:Bool = false;
		var prevPrivate:Bool = false;
		var currPrivate:Bool = false;
		switch (prevTokenType) {
			case FUNCTION(name, visibility, isStatic, isInline, isOverride, isFinal, isExtern):
				prevVar = false;
				prevStatic = isStatic;
				prevPrivate = (visibility == PRIVATE);
			case VAR(name, visibility, isStatic, isInline, isFinal, isExtern):
				prevVar = true;
				prevStatic = isStatic;
				prevPrivate = (visibility == PRIVATE);
			case PROP(name, visibility, isStatic, getter, setter):
				prevVar = true;
				prevStatic = isStatic;
				prevPrivate = (visibility == PRIVATE);
			case UNKNOWN:
				return;
		}
		switch (currTokenType) {
			case FUNCTION(name, visibility, isStatic, isInline, isOverride, isFinal, isExtern):
				currVar = false;
				currStatic = isStatic;
				currPrivate = (visibility == PRIVATE);
			case VAR(name, visibility, isStatic, isInline, isFinal, isExtern):
				currVar = true;
				currStatic = isStatic;
				currPrivate = (visibility == PRIVATE);
			case PROP(name, visibility, isStatic, getter, setter):
				currVar = true;
				currStatic = isStatic;
				currPrivate = (visibility == PRIVATE);
			case UNKNOWN:
				return;
		}
		// only vars
		if ((prevVar == currVar) && prevVar) {
			if (prevStatic != currStatic) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterClassStaticVars);
				return;
			}
			if (prevStatic) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenClassStaticVars);
				return;
			}
			if (prevPrivate != currPrivate) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterClassPrivateVars);
				return;
			}
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenClassVars);
			return;
		}

		// only functions
		if ((prevVar == currVar) && !prevVar) {
			if (prevStatic != currStatic) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterClassStaticFunctions);
				return;
			}
			if (prevStatic) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenClassStaticFunctions);
				return;
			}
			if (prevPrivate != currPrivate) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterClassPrivateFunctions);
				return;
			}
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenClassFunctions);
			return;
		}
		// transition between vars and functions
		parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterClassVars);
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