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
		markClassesAndAbstracts(parsedCode, config);
		markEnumAbstracts(parsedCode, config);
		markRightCurly(parsedCode, config);
	}

	public static function finalRun(codeLines:CodeLines, config:EmptyLinesConfig) {
		for (line in codeLines.lines) {
			if (line.emptyLinesAfter > config.maxAnywhereInFile) {
				line.emptyLinesAfter = config.maxAnywhereInFile;
			}
		}
		codeLines.lines[codeLines.lines.length - 1].emptyLinesAfter = config.beforeEndOfFile;
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

	static function markClassesAndAbstracts(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var classes:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdClass), Kwd(KwdAbstract)], ALL);
		for (c in classes) {
			if (TokenTreeCheckUtils.isTypeEnumAbstract(c)) {
				continue;
			}
			var typeConfig:ClassFieldsEmtpyLinesConfig = null;
			switch (c.tok) {
				case Kwd(KwdClass):
					typeConfig = config.classEmptyLines;
				case Kwd(KwdAbstract):
					typeConfig = config.abstractEmptyLines;
				default:
					continue;
			}
			var block:TokenTree = c.access().firstChild().firstOf(BrOpen).token;
			if (block != null) {
				parsedCode.tokenList.emptyLinesAfter(block, typeConfig.beginType);
			}

			var functions:Array<TokenTree> = c.filter([Kwd(KwdFunction), Kwd(KwdVar)], FIRST);

			var prevToken:TokenTree = null;
			var prevTokenType:TokenFieldType = null;
			var currToken:TokenTree = null;
			var currTokenType:TokenFieldType = null;
			for (func in functions) {
				currToken = func;
				currTokenType = FieldUtils.getFieldType(func, PRIVATE);
				markClassFieldEmptyLines(parsedCode, prevToken, prevTokenType, currToken, currTokenType, typeConfig);
				prevToken = currToken;
				prevTokenType = currTokenType;
			}
		}
	}

	static function markClassFieldEmptyLines(parsedCode:ParsedCode, prevToken:TokenTree, prevTokenType:TokenFieldType, currToken:TokenTree,
		currTokenType:TokenFieldType, config:ClassFieldsEmtpyLinesConfig) {
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
		if (prevVar != currVar) {
			// transition between vars and functions
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterVars);
			return;
		}
		if (prevVar) {
			// only vars
			if (prevStatic != currStatic) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterStaticVars);
				return;
			}
			if (prevStatic) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenStaticVars);
				return;
			}
			if (prevPrivate != currPrivate) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterPrivateVars);
				return;
			}
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenVars);
			return;
		} else {
			// only functions
			if (prevStatic != currStatic) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterStaticFunctions);
				return;
			}
			if (prevStatic) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenStaticFunctions);
				return;
			}
			if (prevPrivate != currPrivate) {
				parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterPrivateFunctions);
				return;
			}
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenFunctions);
			return;
		}
	}

	static function markEnumAbstracts(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var abstracts:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdAbstract), Kwd(KwdEnum)], ALL);
		for (c in abstracts) {
			if (!TokenTreeCheckUtils.isTypeEnumAbstract(c)) {
				continue;
			}
			var block:TokenTree = c.access().firstChild().firstOf(BrOpen).token;
			if (block != null) {
				parsedCode.tokenList.emptyLinesAfter(block, config.beginEnumAbstract);
			}

			var functions:Array<TokenTree> = c.filter([Kwd(KwdFunction), Kwd(KwdVar)], FIRST);

			var prevToken:TokenTree = null;
			var prevTokenType:TokenFieldType = null;
			var currToken:TokenTree = null;
			var currTokenType:TokenFieldType = null;
			for (func in functions) {
				currToken = func;
				currTokenType = FieldUtils.getFieldType(func, PUBLIC);
				markEnumAbstractFieldEmptyLines(parsedCode, prevToken, prevTokenType, currToken, currTokenType, config);
				prevToken = currToken;
				prevTokenType = currTokenType;
			}
		}
	}

	static function markEnumAbstractFieldEmptyLines(parsedCode:ParsedCode, prevToken:TokenTree, prevTokenType:TokenFieldType, currToken:TokenTree,
		currTokenType:TokenFieldType, config:EmptyLinesConfig) {
		if (prevToken == null) {
			return;
		}
		var prevVar:Bool = false;
		var currVar:Bool = false;
		switch (prevTokenType) {
			case FUNCTION(name, visibility, isStatic, isInline, isOverride, isFinal, isExtern):
				prevVar = false;
			case VAR(name, visibility, isStatic, isInline, isFinal, isExtern):
				prevVar = true;
			case PROP(name, visibility, isStatic, getter, setter):
				prevVar = true;
			case UNKNOWN:
				return;
		}
		switch (currTokenType) {
			case FUNCTION(name, visibility, isStatic, isInline, isOverride, isFinal, isExtern):
				currVar = false;
			case VAR(name, visibility, isStatic, isInline, isFinal, isExtern):
				currVar = true;
			case PROP(name, visibility, isStatic, getter, setter):
				currVar = true;
			case UNKNOWN:
				return;
		}
		if (prevVar != currVar) {
			// transition between vars and functions
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterEnumAbstractVars);
			return;
		}
		if (prevVar) {
			// only vars
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenEnumAbstractVars);
			return;
		} else {
			// only functions
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenEnumAbstractFunctions);
			return;
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

	static function markRightCurly(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var brCloses:Array<TokenTree> = parsedCode.root.filter([BrClose], ALL);
		for (br in brCloses) {
			parsedCode.tokenList.emptyLinesBefore(br, config.beforeRightCurly);
		}
	}

	static function keepExistingEmptyLines(parsedCode:ParsedCode) {
		var funcs:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdFunction)], ALL);
		for (func in funcs) {
			var block:TokenTree = func.access().firstChild().is(BrOpen).token;
			if (block == null) {
				block = func.access().firstChild().firstOf(BrOpen).token;
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