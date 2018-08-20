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
		markEnums(parsedCode, config);
		markTypedefs(parsedCode, config);
		markSharp(parsedCode, config.conditionalsEmptyLines);
		if (config.beforeDocCommentEmptyLines != Ignore) {
			markComments(parsedCode, config);
		}
		if (config.beforeRightCurly == Remove) {
			markRightCurly(parsedCode);
		}
		if (config.afterLeftCurly == Remove) {
			markLeftCurly(parsedCode);
		}
		if (config.afterReturn == Remove) {
			markReturn(parsedCode);
		}
		if ((config.beforeBlocks == Remove) || (config.afterBlocks == Remove)) {
			markAroundBlocks(parsedCode, config);
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
				case Sharp(MarkLineEnds.SHARP_ELSE), Sharp(MarkLineEnds.SHARP_ELSE_IF):
				case Sharp(MarkLineEnds.SHARP_END):
					parsedCode.tokenList.emptyLinesAfterSubTree(lastImport.nextSibling, config.afterImportsUsing);
				default:
					parsedCode.tokenList.emptyLinesAfterSubTree(lastImport, config.afterImportsUsing);
			}
		}
		lastImport = null;
		var isImport:Bool = true;
		for (token in imports) {
			var newIsImport:Bool;
			var effectiveToken:TokenTree = token;
			switch (token.tok) {
				case Kwd(KwdImport):
					newIsImport = true;
				case Kwd(KwdUsing):
					newIsImport = false;
				default:
					continue;
			}
			if (token.nextSibling != null) {
				switch (token.nextSibling.tok) {
					case Sharp(MarkLineEnds.SHARP_END):
						effectiveToken = token.nextSibling;
					default:
				}
			}
			if (lastImport == null) {
				lastImport = effectiveToken;
				isImport = newIsImport;
				continue;
			}
			if (newIsImport != isImport) {
				parsedCode.tokenList.emptyLinesAfterSubTree(lastImport, config.beforeUsing);
			}
			isImport = newIsImport;
			lastImport = effectiveToken;
		}
	}

	static function markClassesAndAbstracts(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var classes:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Kwd(KwdClass), Kwd(KwdAbstract):
					FOUND_SKIP_SUBTREE;
				default:
					GO_DEEPER;
			}
		});

		for (c in classes) {
			if (TokenTreeCheckUtils.isTypeEnumAbstract(c)) {
				markEnumAbstracts(c, parsedCode, config.enumAbstractEmptyLines);
				continue;
			}
			var typeConfig:ClassFieldsEmptyLinesConfig = null;
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
			currTokenType:TokenFieldType, config:ClassFieldsEmptyLinesConfig) {
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

	static function markExternClass(c:TokenTree, parsedCode:ParsedCode, config:InterfaceFieldsEmptyLinesConfig) {
		var block:TokenTree = c.access().firstChild().firstOf(BrOpen).token;
		if (block == null) {
			return;
		}
		parsedCode.tokenList.emptyLinesAfter(block, config.beginType);
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
			currTokenType:TokenFieldType, config:InterfaceFieldsEmptyLinesConfig) {
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

	static function markEnumAbstracts(token:TokenTree, parsedCode:ParsedCode, config:EnumAbstractFieldsEmptyLinesConfig) {
		var block:TokenTree = token.access().firstChild().firstOf(BrOpen).token;
		if (block != null) {
			parsedCode.tokenList.emptyLinesAfter(block, config.beginType);
		}

		var functions:Array<TokenTree> = token.filter([Kwd(KwdFunction), Kwd(KwdVar)], FIRST);

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

	static function markEnumAbstractFieldEmptyLines(parsedCode:ParsedCode, prevToken:TokenTree, prevTokenType:TokenFieldType, currToken:TokenTree,
			currTokenType:TokenFieldType, config:EnumAbstractFieldsEmptyLinesConfig) {
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

	static function markEnums(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var enums:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdEnum)], ALL);
		for (e in enums) {
			if (e.parent.tok != null) {
				switch (e.parent.tok) {
					case Const(_):
						continue;
					case At, DblDot:
						continue;
					default:
				}
			}
			var block:TokenTree = e.access().firstChild().firstOf(BrOpen).token;
			if (block == null) {
				continue;
			}
			markEnumFields(block, parsedCode, config.enumEmptyLines);
		}
	}

	static function markEnumFields(block:TokenTree, parsedCode:ParsedCode, config:TypedefFieldsEmptyLinesConfig) {
		parsedCode.tokenList.emptyLinesAfter(block, config.beginType);
		if ((block.children == null) || (block.children.length <= 0)) {
			return;
		}
		var prevToken:TokenTree = null;
		for (child in block.children) {
			switch (child.tok) {
				case BrClose:
					return;
				case Comment(_), CommentLine(_):
					continue;
				default:
			}
			if (prevToken == null) {
				prevToken = child;
				continue;
			}
			parsedCode.tokenList.emptyLinesAfterSubTree(prevToken, config.betweenFields);
			prevToken = child;
		}
	}

	static function markTypedefs(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var typedefs:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdTypedef)], ALL);
		for (t in typedefs) {
			var block:TokenTree = t.access().firstChild().firstOf(Binop(OpAssign)).firstOf(BrOpen).token;
			if (block == null) {
				continue;
			}
			markEnumFields(block, parsedCode, config.typedefEmptyLines);
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
		var types:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Kwd(KwdAbstract), Kwd(KwdClass), Kwd(KwdEnum), Kwd(KwdInterface), Kwd(KwdTypedef):
					FOUND_SKIP_SUBTREE;
				case Kwd(KwdVar), Kwd(KwdFunction):
					FOUND_SKIP_SUBTREE;
				case Const(CIdent("final")):
					FOUND_SKIP_SUBTREE;
				#if (haxe_ver >= 4.0)
				case Kwd(KwdFinal):
					FOUND_SKIP_SUBTREE;
				#end
				default:
					GO_DEEPER;
			}
		});
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
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(ret);
			if (lastChild == null) {
				continue;
			}
			var next:TokenInfo = parsedCode.tokenList.getNextToken(lastChild);
			if (next == null) {
				continue;
			}
			switch (next.token.tok) {
				case BrClose:
					parsedCode.tokenList.emptyLinesAfterSubTree(ret, 0);
				default:
			}
		}
	}

	static function markSharp(parsedCode:ParsedCode, config:ConditionalEmptyLinesConfig) {
		var sharps:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Sharp(_):
					FOUND_GO_DEEPER;
				default:
					GO_DEEPER;
			}
		});
		for (sharp in sharps) {
			var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(sharp);
			if ((prev != null) && (prev.whitespaceAfter != Newline)) {
				continue;
			}
			switch (sharp.tok) {
				case Sharp(MarkLineEnds.SHARP_IF):
					parsedCode.tokenList.emptyLinesAfterSubTree(sharp.getFirstChild(), config.afterIf);
				case Sharp(MarkLineEnds.SHARP_ELSE_IF):
					parsedCode.tokenList.emptyLinesBefore(sharp, config.beforeElse);
					parsedCode.tokenList.emptyLinesAfterSubTree(sharp.getFirstChild(), config.afterIf);
				case Sharp(MarkLineEnds.SHARP_ELSE):
					parsedCode.tokenList.emptyLinesBefore(sharp, config.beforeElse);
					parsedCode.tokenList.emptyLinesAfter(sharp, config.afterElse);
				case Sharp(MarkLineEnds.SHARP_END):
					parsedCode.tokenList.emptyLinesBefore(sharp, config.beforeEnd);
				case Sharp(MarkLineEnds.SHARP_ERROR):
					parsedCode.tokenList.emptyLinesBefore(sharp, config.beforeError);
					parsedCode.tokenList.emptyLinesAfterSubTree(sharp, config.afterError);
				default:
			}
		}
	}

	static function markComments(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		var comments:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Comment(text):
					if (text.startsWith("*")) FOUND_GO_DEEPER; else GO_DEEPER;
				default:
					GO_DEEPER;
			}
		});
		for (comment in comments) {
			if (comment.previousSibling == null) {
				continue;
			}
			if ((comment.parent != null) && (comment.parent.tok != null)) {
				switch (comment.parent.tok) {
					case Sharp(_):
						if (comment.parent.getFirstChild() == comment.previousSibling) {
							continue;
						}
					default:
				}
			}
			if (comment.nextSibling == null) {
				continue;
			}
			var next:TokenTree = comment.nextSibling;
			var found:Bool = true;
			while (next != null) {
				switch (next.tok) {
					case Kwd(KwdVar):
					case Kwd(KwdFunction):
					case Kwd(KwdAbstract):
					case Kwd(KwdClass):
					case Kwd(KwdEnum):
					case Kwd(KwdInterface):
					case Kwd(KwdTypedef):
					case Const(CIdent(_)):
					#if (haxe_ver >= 4.0)
					case Kwd(KwdFinal):
					#end
					case Sharp(_):
					case CommentLine(_):
						next = next.nextSibling;
						continue;
					default:
						found = false;
				}
				break;
			}
			if (!found) {
				continue;
			}
			switch (config.beforeDocCommentEmptyLines) {
				case Ignore:
				case None:
					parsedCode.tokenList.emptyLinesBefore(comment, 0);
				case One:
					parsedCode.tokenList.emptyLinesBefore(comment, 1);
			}
		}
	}

	static function markAroundBlocks(parsedCode:ParsedCode, config:EmptyLinesConfig) {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Kwd(KwdIf):
					removeEmptyLinesAroundBlock(token.children[1], parsedCode, config.beforeBlocks, Keep);
					var block:TokenTree = token.access().firstOf(Kwd(KwdElse)).previousSibling().token;
					if (block != null) {
						removeEmptyLinesAroundBlock(block, parsedCode, Keep, config.afterBlocks);
					}
				case Kwd(KwdElse):
					removeEmptyLinesAroundBlock(token.getFirstChild(), parsedCode, config.beforeBlocks, Keep);
				case Kwd(KwdCase), Kwd(KwdDefault):
					var block:TokenTree = token.access().firstOf(DblDot).firstChild().token;
					removeEmptyLinesAroundBlock(block, parsedCode, config.beforeBlocks, Keep);
				case Kwd(KwdFunction):
				case Kwd(KwdFor):
					removeEmptyLinesAroundBlock(token.children[1], parsedCode, config.beforeBlocks, Keep);
				case Kwd(KwdDo):
					removeEmptyLinesAroundBlock(token.getFirstChild(), parsedCode, config.beforeBlocks, Keep);
					var block:TokenTree = token.access().lastChild().previousSibling().token;
					removeEmptyLinesAroundBlock(block, parsedCode, Keep, config.afterBlocks);
				case Kwd(KwdWhile):
					if ((token.parent == null) || (!token.parent.is(Kwd(KwdDo)))) {
						removeEmptyLinesAroundBlock(token.children[1], parsedCode, config.beforeBlocks, Keep);
					}
				case Kwd(KwdTry):
					removeEmptyLinesAroundBlock(token.getFirstChild(), parsedCode, config.beforeBlocks, Keep);
					var block:TokenTree = token.access().lastChild().previousSibling().token;
					removeEmptyLinesAroundBlock(block, parsedCode, Keep, config.afterBlocks);
				case Kwd(KwdCatch):
					removeEmptyLinesAroundBlock(token.children[1], parsedCode, config.beforeBlocks, Keep);
				default:
			}
			return GO_DEEPER;
		});
	}

	static function removeEmptyLinesAroundBlock(block:TokenTree, parsedCode:ParsedCode, before:KeepEmptyLinesPolicy, after:KeepEmptyLinesPolicy) {
		if (block == null) {
			return;
		}
		if (before == Remove) {
			var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(block);
			if (prev != null) {
				parsedCode.tokenList.emptyLinesAfter(prev.token, 0);
			}
		}
		if (after == Remove) {
			parsedCode.tokenList.emptyLinesAfterSubTree(block, 0);
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
