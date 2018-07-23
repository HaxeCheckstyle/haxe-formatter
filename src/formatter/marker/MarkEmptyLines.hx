package formatter.marker;

import tokentree.utils.FieldUtils;
import formatter.codedata.CodeLine;
import formatter.codedata.CodeLines;
import formatter.config.EmptyLinesConfig;

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
		markInterfaces(parsedCode, config);
		markEnumAbstracts(parsedCode, config.enumAbstractEmptyLines);
		if (config.beforeRightCurly == Remove) {
			markRightCurly(parsedCode);
		}
		if (config.afterLeftCurly == Remove) {
			markLeftCurly(parsedCode);
		}
		if (config.afterReturn == Remove) {
			markReturn(parsedCode);
		}
	}

	public static function finalRun(codeLines:CodeLines, config:EmptyLinesConfig) {
		if (codeLines.lines.length <= 0) {
			return;
		}
		for (line in codeLines.lines) {
			if (line.verbatim) {
				continue;
			}
			if (line.emptyLinesAfter > config.maxAnywhereInFile) {
				line.emptyLinesAfter = config.maxAnywhereInFile;
			}
		}
		var lastLine:CodeLine = codeLines.lines[codeLines.lines.length - 1];
		if (lastLine.verbatim) {
			return;
		}
		lastLine.emptyLinesAfter = config.finalNewline ? 1 : 0;
	}

	static function markImports(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var imports:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdImport), Kwd(KwdUsing)], ALL);
		if (imports.length <= 0) {
			return;
		}

		var lastImport:TokenTree = imports[imports.length - 1];
		if (lastImport.nextSibling != null) {
			switch (lastImport.nextSibling.tok) {
				case Sharp(MarkLineEnds.SHARP_END), Sharp(MarkLineEnds.SHARP_ELSE), Sharp(MarkLineEnds.SHARP_ELSE_IF):
				default:
					parsedCode.tokenList.emptyLinesAfterSubTree(lastImport, config.afterImportsUsing);
			}
		}
		lastImport = null;
		var isImport:Bool = true;
		for (token in imports) {
			var newIsImport:Bool;
			switch (token.tok) {
				case Kwd(KwdImport):
					newIsImport = true;
				case Kwd(KwdUsing):
					newIsImport = false;
				default:
					continue;
			}
			if (lastImport == null) {
				lastImport = token;
				isImport = newIsImport;
				continue;
			}
			if (newIsImport != isImport) {
				parsedCode.tokenList.emptyLinesAfterSubTree(lastImport, config.beforeUsing);
			}
			isImport = newIsImport;
			lastImport = token;
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
					if (c.access().firstChild().firstOf(Kwd(KwdExtern)).exists()) {
						markExternClass(c, parsedCode, config.externClassEmptyLines);
						continue;
					}
				case Kwd(KwdAbstract):
					typeConfig = config.abstractEmptyLines;
				default:
					continue;
			}
			var block:TokenTree = c.access().firstChild().firstOf(BrOpen).token;
			if (block != null) {
				parsedCode.tokenList.emptyLinesAfter(block, typeConfig.beginType);
			}

			var finalTokDef:TokenDef = #if (haxe_ver >= 4.0) Kwd(KwdFinal); #else Const(CIdent("final")); #end
			var functions:Array<TokenTree> = c.filter([Kwd(KwdFunction), Kwd(KwdVar), finalTokDef], FIRST);
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
		prevToken = skipSharpFields(prevToken);
		if (prevToken == null) {
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

	static function markExternClass(c:TokenTree, parsedCode:ParsedCode, config:InterfaceFieldsEmtpyLinesConfig) {
		var block:TokenTree = c.access().firstChild().firstOf(BrOpen).token;
		if (block != null) {
			parsedCode.tokenList.emptyLinesAfter(block, config.beginType);
		}
		var finalTokDef:TokenDef = #if (haxe_ver >= 4.0) Kwd(KwdFinal); #else Const(CIdent("final")); #end
		var fields:Array<TokenTree> = block.filter([Kwd(KwdFunction), Kwd(KwdVar), finalTokDef], FIRST);

		var prevToken:TokenTree = null;
		var prevTokenType:TokenFieldType = null;
		var currToken:TokenTree = null;
		var currTokenType:TokenFieldType = null;
		for (field in fields) {
			currToken = field;
			currTokenType = FieldUtils.getFieldType(field, PUBLIC);
			markInterfaceEmptyLines(parsedCode, prevToken, prevTokenType, currToken, currTokenType, config);
			prevToken = currToken;
			prevTokenType = currTokenType;
		}
	}

	static function markInterfaces(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var interfaces:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdInterface)], ALL);
		for (i in interfaces) {
			markExternClass(i, parsedCode, config.interfaceEmptyLines);
		}
	}

	static function markInterfaceEmptyLines(parsedCode:ParsedCode, prevToken:TokenTree, prevTokenType:TokenFieldType, currToken:TokenTree,
		currTokenType:TokenFieldType, config:InterfaceFieldsEmtpyLinesConfig) {
		if (prevToken == null) {
			return;
		}
		var prevVar:Bool = false;
		var currVar:Bool = false;
		switch (prevTokenType) {
			case FUNCTION(name, _, _, _, _, _, _):
				prevVar = false;
			case VAR(name, _, _, _, _, _):
				prevVar = true;
			case PROP(name, _, _, _, _):
				prevVar = true;
			case UNKNOWN:
				return;
		}
		switch (currTokenType) {
			case FUNCTION(name, _, _, _, _, _, _):
				currVar = false;
			case VAR(name, _, _, _, _, _):
				currVar = true;
			case PROP(name, _, _, _, _):
				currVar = true;
			case UNKNOWN:
				return;
		}
		prevToken = skipSharpFields(prevToken);
		if (prevToken == null) {
			return;
		}
		if (prevVar != currVar) {
			// transition between vars and functions
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterVars);
			return;
		}
		if (prevVar) {
			// only vars
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenVars);
			return;
		} else {
			// only functions
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenFunctions);
			return;
		}
	}

	static function markEnumAbstracts(parsedCode:ParsedCode, config:EnumAbstractFieldsEmtpyLinesConfig) {
		var abstracts:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdAbstract), Kwd(KwdEnum)], ALL);
		for (c in abstracts) {
			if (!TokenTreeCheckUtils.isTypeEnumAbstract(c)) {
				continue;
			}
			var block:TokenTree = c.access().firstChild().firstOf(BrOpen).token;
			if (block != null) {
				parsedCode.tokenList.emptyLinesAfter(block, config.beginType);
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
		currTokenType:TokenFieldType, config:EnumAbstractFieldsEmtpyLinesConfig) {
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
		prevToken = skipSharpFields(prevToken);
		if (prevToken == null) {
			return;
		}
		if (prevVar != currVar) {
			// transition between vars and functions
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.afterVars);
			return;
		}
		if (prevVar) {
			// only vars
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenVars);
			return;
		} else {
			// only functions
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenFunctions);
			return;
		}
	}

	static function skipSharpFields(prevToken:TokenTree):TokenTree {
		var next:TokenTree = prevToken.nextSibling;
		if (next == null) {
			return prevToken;
		}
		switch (next.tok) {
			case Sharp(MarkLineEnds.SHARP_END):
				return next;
			case Sharp(MarkLineEnds.SHARP_IF):
				return prevToken;
			case Sharp(_):
				return null;
			default:
		}
		return prevToken;
	}

	static function betweenTypes(parsedCode:ParsedCode, count:Int) {
		var types:Array<TokenTree> = parsedCode.root.filter([
			Kwd(KwdAbstract), Kwd(KwdClass), Kwd(KwdEnum), Kwd(KwdInterface), Kwd(KwdTypedef)
		], ALL);
		if (types.length <= 1) {
			return;
		}
		for (type in types) {
			if (type.nextSibling == null) {
				continue;
			}
			var sibling:TokenTree = type.nextSibling;
			var skip:Bool = false;
			while (sibling != null) {
				switch (sibling.tok) {
					case Sharp(MarkLineEnds.SHARP_IF):
						break;
					case Sharp(MarkLineEnds.SHARP_ELSE), Sharp(MarkLineEnds.SHARP_ELSE_IF):
						skip = true;
						break;
					case Sharp(MarkLineEnds.SHARP_END):
					case Comment(_), CommentLine(_):
						break;
					case Kwd(_):
						break;
					default:
				}
				type = sibling;
				sibling = type.nextSibling;
			}
			if (!skip) {
				parsedCode.tokenList.emptyLinesAfterSubTree(type, count);
			}
		}
	}

	static function markLeftCurly(parsedCode:ParsedCode) {
		var brOpens:Array<TokenTree> = parsedCode.root.filter([BrOpen], ALL);
		for (br in brOpens) {
			parsedCode.tokenList.emptyLinesAfter(br, 0);
		}
	}

	static function markRightCurly(parsedCode:ParsedCode) {
		var brCloses:Array<TokenTree> = parsedCode.root.filter([BrClose], ALL);
		for (br in brCloses) {
			parsedCode.tokenList.emptyLinesBefore(br, 0);
		}
	}

	static function markReturn(parsedCode:ParsedCode) {
		var returns:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdReturn)], ALL);
		for (ret in returns) {
			parsedCode.tokenList.emptyLinesAfterSubTree(ret, 0);
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
