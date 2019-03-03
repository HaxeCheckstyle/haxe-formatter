package formatter.marker;

import tokentree.utils.FieldUtils;
import formatter.codedata.CodeLine;
import formatter.codedata.CodeLines;
import formatter.config.EmptyLinesConfig;

class MarkEmptyLines extends MarkerBase {
	public static inline var FINAL:String = "final";

	public function run() {
		keepExistingEmptyLines();

		var packs:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdPackage)], ALL);
		packs.reverse();
		for (pack in packs) {
			if (TokenTreeCheckUtils.isMetadata(pack)) {
				continue;
			}
			emptyLinesBefore(pack, config.emptyLines.beforePackage);
			emptyLinesAfter(pack, config.emptyLines.afterPackage);
		}

		betweenTypes();

		markImports();
		markClassesAndAbstracts();
		markMacroClasses();
		markInterfaces();
		markEnums();
		markTypedefs();
		markSharp();
		if (config.emptyLines.beforeDocCommentEmptyLines != Ignore) {
			markDocComments();
		}
		markMultilineComments();
		markFileHeader();
		if (config.emptyLines.beforeRightCurly == Remove) {
			markRightCurly();
		}
		if (config.emptyLines.afterLeftCurly == Remove) {
			markLeftCurly();
		}
		if (config.emptyLines.afterReturn == Remove) {
			markReturn();
		}
		if ((config.emptyLines.beforeBlocks == Remove) || (config.emptyLines.afterBlocks == Remove)) {
			markAroundBlocks();
		}
	}

	public function finalRun(codeLines:CodeLines) {
		if (codeLines.lines.length <= 0) {
			return;
		}
		for (line in codeLines.lines) {
			if (line.verbatim) {
				continue;
			}
			if (line.emptyLinesAfter > config.emptyLines.maxAnywhereInFile) {
				line.emptyLinesAfter = config.emptyLines.maxAnywhereInFile;
			}
		}
		var lastLine:CodeLine = codeLines.lines[codeLines.lines.length - 1];
		if (lastLine.verbatim) {
			return;
		}
		lastLine.emptyLinesAfter = config.emptyLines.finalNewline ? 1 : 0;
	}

	function markImports() {
		var imports:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Kwd(KwdImport), Kwd(KwdUsing):
					if (TokenTreeCheckUtils.isMetadata(token)) {
						return SKIP_SUBTREE;
					} else {
						return FOUND_SKIP_SUBTREE;
					}
				default:
					return GO_DEEPER;
			}
		});
		if (imports.length <= 0) {
			return;
		}

		var lastImport:TokenTree = imports[imports.length - 1];
		var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(lastImport);
		var afterImport:TokenInfo = getNextToken(lastChild);
		if (afterImport != null) {
			switch (afterImport.token.tok) {
				case Sharp(MarkLineEnds.SHARP_ELSE), Sharp(MarkLineEnds.SHARP_ELSE_IF):
				case Sharp(MarkLineEnds.SHARP_END):
					emptyLinesAfterSubTree(afterImport.token, config.emptyLines.importAndUsing.beforeType);
				default:
					emptyLinesAfterSubTree(lastImport, config.emptyLines.importAndUsing.beforeType);
			}
		}

		lastImport = null;
		var prevInfo:ImportPackageInfo = null;
		for (token in imports) {
			var newInfo:ImportPackageInfo = getImportInfo(token);

			var lastToken:TokenTree = TokenTreeCheckUtils.getLastToken(token);
			var next:TokenInfo = getNextToken(lastToken);
			if (next != null) {
				switch (next.token.tok) {
					case Sharp(MarkLineEnds.SHARP_END):
						newInfo.token = next.token;
					default:
				}
			}
			if (prevInfo == null) {
				prevInfo = newInfo;
				continue;
			}

			if (prevInfo.isImport == newInfo.isImport) {
				switch (config.emptyLines.importAndUsing.betweenImportsLevel) {
					case All:
						emptyLinesAfterSubTree(prevInfo.token, config.emptyLines.importAndUsing.betweenImports);
					case FirstLevelPackage:
						if (prevInfo.firstLevelPackage != newInfo.firstLevelPackage) {
							emptyLinesAfterSubTree(prevInfo.token, config.emptyLines.importAndUsing.betweenImports);
						}
					case SecondLevelPackage:
						if (prevInfo.secondLevelPackage != newInfo.secondLevelPackage) {
							emptyLinesAfterSubTree(prevInfo.token, config.emptyLines.importAndUsing.betweenImports);
						}
					case ThirdLevelPackage:
						if (prevInfo.thirdLevelPackage != newInfo.thirdLevelPackage) {
							emptyLinesAfterSubTree(prevInfo.token, config.emptyLines.importAndUsing.betweenImports);
						}
					case FourthLevelPackage:
						if (prevInfo.fourthLevelPackage != newInfo.fourthLevelPackage) {
							emptyLinesAfterSubTree(prevInfo.token, config.emptyLines.importAndUsing.betweenImports);
						}
					case FifthLevelPackage:
						if (prevInfo.fifthLevelPackage != newInfo.fifthLevelPackage) {
							emptyLinesAfterSubTree(prevInfo.token, config.emptyLines.importAndUsing.betweenImports);
						}
					case FullPackage:
						if (prevInfo.fullPackage != newInfo.fullPackage) {
							emptyLinesAfterSubTree(prevInfo.token, config.emptyLines.importAndUsing.betweenImports);
						}
				}
			} else {
				emptyLinesAfterSubTree(prevInfo.token, config.emptyLines.importAndUsing.beforeUsing);
			}
			prevInfo = newInfo;
		}
	}

	function getImportInfo(token:TokenTree):ImportPackageInfo {
		var info:ImportPackageInfo = {
			token: token,
			isImport: false,
			firstLevelPackage: "",
			secondLevelPackage: "",
			thirdLevelPackage: "",
			fourthLevelPackage: "",
			fifthLevelPackage: "",
			fullPackage: "",
			moduleName: ""
		};
		switch (token.tok) {
			case Kwd(KwdImport):
				info.isImport = true;
			case Kwd(KwdUsing):
				info.isImport = false;
			default:
		}
		var parts:Array<String> = [];
		token = token.getFirstChild();
		while (true) {
			switch (token.tok) {
				case Const(CIdent(text)):
					parts.push(text);
				case Kwd(_):
					parts.push('$token');
				default:
			}
			token = token.getFirstChild();
			if ((token == null) || (!token.is(Dot))) {
				break;
			}
			token = token.getFirstChild();
			if (token == null) {
				break;
			}
		}
		info.moduleName = parts.pop();
		info.fullPackage = parts.join(".");
		if (parts.length > 0) {
			info.firstLevelPackage = parts[0];
		}
		if (parts.length > 1) {
			info.secondLevelPackage = parts.slice(0, 2).join(".");
		} else {
			info.secondLevelPackage = info.firstLevelPackage;
		}
		if (parts.length > 2) {
			info.thirdLevelPackage = parts.slice(0, 3).join(".");
		} else {
			info.thirdLevelPackage = info.secondLevelPackage;
		}
		if (parts.length > 3) {
			info.fourthLevelPackage = parts.slice(0, 4).join(".");
		} else {
			info.fourthLevelPackage = info.thirdLevelPackage;
		}
		if (parts.length > 4) {
			info.fifthLevelPackage = parts.slice(0, 5).join(".");
		} else {
			info.fifthLevelPackage = info.fourthLevelPackage;
		}
		return info;
	}

	function markClassesAndAbstracts() {
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
				markEnumAbstracts(c);
				continue;
			}
			var typeConfig:ClassFieldsEmptyLinesConfig = null;
			switch (c.tok) {
				case Kwd(KwdClass):
					typeConfig = config.emptyLines.classEmptyLines;
					if (c.access().firstChild().firstOf(Kwd(KwdExtern)).exists()) {
						markExternClass(c, config.emptyLines.externClassEmptyLines);
						continue;
					}
				case Kwd(KwdAbstract):
					typeConfig = config.emptyLines.abstractEmptyLines;
				default:
					continue;
			}
			var block:TokenTree = c.access().firstChild().firstOf(BrOpen).token;
			markBeginAndEndType(block, typeConfig.beginType, typeConfig.endType);

			var finalTokDef:TokenDef = #if (haxe_ver >= 4.0) Kwd(KwdFinal); #else Const(CIdent(FINAL)); #end
			var functions:Array<TokenTree> = findClassAndAbstractFields(c);
			var prevToken:TokenTree = null;
			var prevTokenType:TokenFieldType = null;
			var currToken:TokenTree = null;
			var currTokenType:TokenFieldType = null;
			for (func in functions) {
				currToken = func;
				currTokenType = FieldUtils.getFieldType(func, PRIVATE);
				markClassFieldEmptyLines(prevToken, prevTokenType, currToken, currTokenType, typeConfig);
				prevToken = currToken;
				prevTokenType = currTokenType;
			}
		}
	}

	function markMacroClasses() {
		var classes:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Kwd(KwdClass):
					if ((token.parent == null) || (token.parent.tok == null)) {
						return GO_DEEPER;
					}
					switch (token.parent.tok) {
						case Kwd(KwdMacro):
							return FOUND_SKIP_SUBTREE;
						default:
							return GO_DEEPER;
					}
				default:
					return GO_DEEPER;
			}
		});

		for (c in classes) {
			var typeConfig:ClassFieldsEmptyLinesConfig = config.emptyLines.macroClassEmptyLines;
			var block:TokenTree = c.access().firstChild().firstOf(BrOpen).token;
			markBeginAndEndType(block, typeConfig.beginType, typeConfig.endType);

			var finalTokDef:TokenDef = #if (haxe_ver >= 4.0) Kwd(KwdFinal); #else Const(CIdent(FINAL)); #end
			var functions:Array<TokenTree> = findClassAndAbstractFields(c);
			var prevToken:TokenTree = null;
			var prevTokenType:TokenFieldType = null;
			var currToken:TokenTree = null;
			var currTokenType:TokenFieldType = null;
			for (func in functions) {
				currToken = func;
				currTokenType = FieldUtils.getFieldType(func, PRIVATE);
				markClassFieldEmptyLines(prevToken, prevTokenType, currToken, currTokenType, typeConfig);
				prevToken = currToken;
				prevTokenType = currTokenType;
			}
		}
	}

	function findClassAndAbstractFields(c:TokenTree):Array<TokenTree> {
		return c.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Kwd(KwdFunction), Kwd(KwdVar):
					FOUND_SKIP_SUBTREE;
				case Const(CIdent(FINAL)):
					FOUND_SKIP_SUBTREE;
				#if (haxe_ver >= 4.0)
				case Kwd(KwdFinal):
					FOUND_SKIP_SUBTREE;
				#end
				case At:
					SKIP_SUBTREE;
				default:
					GO_DEEPER;
			}
		});
	}

	function markBeginAndEndType(brOpen:TokenTree, beginType:Int, endType:Int) {
		if (brOpen == null) {
			return;
		}
		emptyLinesAfter(brOpen, beginType);

		var brClose:TokenTree = brOpen.access().firstOf(BrClose).token;
		if (brClose == null) {
			return;
		}
		emptyLinesBefore(brClose, endType);
	}

	function markClassFieldEmptyLines(prevToken:Null<TokenTree>, prevTokenType:TokenFieldType, currToken:TokenTree, currTokenType:TokenFieldType,
			conf:ClassFieldsEmptyLinesConfig) {
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

		if (!currVar) {
			markLineCommentsBefore(currToken, config.emptyLines.lineCommentsBetweenFunctions);
			markLineCommentsAfter(currToken, config.emptyLines.lineCommentsBetweenFunctions);
		}
		prevToken = skipSharpFields(prevToken);
		if (prevToken == null) {
			return;
		}
		if (prevVar != currVar) {
			// transition between vars and functions
			emptyLinesAfterSubTree(prevToken, conf.afterVars);
			return;
		}
		if (prevVar) {
			// only vars
			if (prevStatic != currStatic) {
				emptyLinesAfterSubTree(prevToken, conf.afterStaticVars);
				return;
			}
			if (prevStatic) {
				emptyLinesAfterSubTree(prevToken, conf.betweenStaticVars);
				return;
			}
			if (prevPrivate != currPrivate) {
				emptyLinesAfterSubTree(prevToken, conf.afterPrivateVars);
				return;
			}
			emptyLinesAfterSubTree(prevToken, conf.betweenVars);
			return;
		} else {
			// only functions
			if (prevStatic != currStatic) {
				emptyLinesAfterSubTree(prevToken, conf.afterStaticFunctions);
				return;
			}
			if (prevStatic) {
				emptyLinesAfterSubTree(prevToken, conf.betweenStaticFunctions);
				return;
			}
			if (prevPrivate != currPrivate) {
				emptyLinesAfterSubTree(prevToken, conf.afterPrivateFunctions);
				return;
			}
			emptyLinesAfterSubTree(prevToken, conf.betweenFunctions);
			return;
		}
	}

	function markLineCommentsBefore(token:TokenTree, count:Int) {
		if (count <= 0) {
			return;
		}
		if (token.previousSibling == null) {
			return;
		}
		var prev:Null<TokenTree> = token.previousSibling;
		while (prev != null) {
			switch (prev.tok) {
				case Comment(_):
				case CommentLine(_):
					var prevInfo:Null<TokenInfo> = getPreviousToken(prev);
					if ((prevInfo == null) || (prevInfo.whitespaceAfter == Newline)) {
						emptyLinesAfter(prev, count);
					}
					return;
				default:
					return;
			}
			prev = prev.previousSibling;
		}
	}

	function markLineCommentsAfter(token:TokenTree, count:Int) {
		if (count <= 0) {
			return;
		}
		if (token.nextSibling == null) {
			return;
		}
		var next:Null<TokenTree> = token.nextSibling;
		switch (next.tok) {
			case CommentLine(_):
				if (isNewLineBefore(next)) {
					emptyLinesBefore(next, count);
				}
			default:
		}
	}

	function markExternClass(c:TokenTree, conf:InterfaceFieldsEmptyLinesConfig) {
		var block:Null<TokenTree> = c.access().firstChild().firstOf(BrOpen).token;
		if (block == null) {
			return;
		}
		markBeginAndEndType(block, conf.beginType, conf.endType);

		var finalTokDef:TokenDef = #if (haxe_ver >= 4.0) Kwd(KwdFinal); #else Const(CIdent(FINAL)); #end
		var fields:Array<TokenTree> = block.filter([Kwd(KwdFunction), Kwd(KwdVar), finalTokDef], FIRST);

		var prevToken:Null<TokenTree> = null;
		var prevTokenType:Null<TokenFieldType> = null;
		var currToken:Null<TokenTree> = null;
		var currTokenType:Null<TokenFieldType> = null;
		for (field in fields) {
			currToken = field;
			currTokenType = FieldUtils.getFieldType(field, PUBLIC);
			markInterfaceEmptyLines(prevToken, prevTokenType, currToken, currTokenType, conf);
			prevToken = currToken;
			prevTokenType = currTokenType;
		}
	}

	function markInterfaces() {
		var interfaces:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdInterface)], ALL);
		for (i in interfaces) {
			markExternClass(i, config.emptyLines.interfaceEmptyLines);
		}
	}

	function markInterfaceEmptyLines(prevToken:Null<TokenTree>, prevTokenType:TokenFieldType, currToken:TokenTree, currTokenType:TokenFieldType,
			conf:InterfaceFieldsEmptyLinesConfig) {
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
			emptyLinesAfterSubTree(prevToken, conf.afterVars);
			return;
		}
		if (prevVar) {
			// only vars
			emptyLinesAfterSubTree(prevToken, conf.betweenVars);
			return;
		} else {
			// only functions
			emptyLinesAfterSubTree(prevToken, conf.betweenFunctions);
			return;
		}
	}

	function markEnumAbstracts(token:TokenTree) {
		var block:Null<TokenTree> = token.access().firstChild().firstOf(BrOpen).token;
		markBeginAndEndType(block, config.emptyLines.enumAbstractEmptyLines.beginType, config.emptyLines.enumAbstractEmptyLines.endType);

		var functions:Array<TokenTree> = token.filter([Kwd(KwdFunction), Kwd(KwdVar)], FIRST);

		var prevToken:Null<TokenTree> = null;
		var prevTokenType:Null<TokenFieldType> = null;
		var currToken:Null<TokenTree> = null;
		var currTokenType:Null<TokenFieldType> = null;
		for (func in functions) {
			currToken = func;
			currTokenType = FieldUtils.getFieldType(func, PUBLIC);
			markEnumAbstractFieldEmptyLines(prevToken, prevTokenType, currToken, currTokenType);
			prevToken = currToken;
			prevTokenType = currTokenType;
		}
	}

	function markEnumAbstractFieldEmptyLines(prevToken:Null<TokenTree>, prevTokenType:TokenFieldType, currToken:TokenTree,
			currTokenType:TokenFieldType) {
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
			emptyLinesAfterSubTree(prevToken, config.emptyLines.enumAbstractEmptyLines.afterVars);
			return;
		}
		if (prevVar) {
			// only vars
			emptyLinesAfterSubTree(prevToken, config.emptyLines.enumAbstractEmptyLines.betweenVars);
			return;
		} else {
			// only functions
			emptyLinesAfterSubTree(prevToken, config.emptyLines.enumAbstractEmptyLines.betweenFunctions);
			return;
		}
	}

	function markEnums() {
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
			markEnumFields(block, config.emptyLines.enumEmptyLines);
		}
	}

	function markEnumFields(block:TokenTree, config:TypedefFieldsEmptyLinesConfig) {
		markBeginAndEndType(block, config.beginType, config.endType);
		if ((block.children == null) || (block.children.length <= 0)) {
			return;
		}
		var prevToken:Null<TokenTree> = null;
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
			emptyLinesAfterSubTree(prevToken, config.betweenFields);
			prevToken = child;
		}
	}

	function markTypedefs() {
		var typedefs:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdTypedef)], ALL);
		for (t in typedefs) {
			var block:Null<TokenTree> = t.access().firstChild().firstOf(Binop(OpAssign)).firstOf(BrOpen).token;
			if (block == null) {
				continue;
			}
			markEnumFields(block, config.emptyLines.typedefEmptyLines);
		}
	}

	function skipSharpFields(prevToken:TokenTree):Null<TokenTree> {
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

	function betweenTypes() {
		if ((config.emptyLines.betweenTypes <= 0) && (config.emptyLines.betweenSingleLineTypes <= 0)) {
			return;
		}

		var types:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Kwd(KwdAbstract), Kwd(KwdClass), Kwd(KwdEnum), Kwd(KwdInterface), Kwd(KwdTypedef):
					FOUND_SKIP_SUBTREE;
				case Kwd(KwdVar), Kwd(KwdFunction):
					FOUND_SKIP_SUBTREE;
				case Const(CIdent(FINAL)):
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
		var prevTypeInfo:Null<TypeEmptyLinesInfo> = null;
		for (type in types) {
			var newTypeInfo:TypeEmptyLinesInfo = getTypeInfo(type);
			markLineCommentsBefore(type, config.emptyLines.lineCommentsBetweenTypes);
			markLineCommentsAfter(type, config.emptyLines.lineCommentsBetweenTypes);
			if (prevTypeInfo == null) {
				prevTypeInfo = newTypeInfo;
				continue;
			}
			var next:Null<TokenInfo> = getNextToken(prevTypeInfo.lastToken);
			if (next != null) {
				switch (next.token.tok) {
					case Sharp(MarkLineEnds.SHARP_ELSE), Sharp(MarkLineEnds.SHARP_ELSE_IF):
						prevTypeInfo = newTypeInfo;
						continue;
					default:
				}
			}
			var emptyLines:Int = config.emptyLines.betweenTypes;
			if (prevTypeInfo.oneLine && newTypeInfo.oneLine) {
				emptyLines = config.emptyLines.betweenSingleLineTypes;
			}
			emptyLinesAfterSubTree(prevTypeInfo.lastToken, emptyLines);
			markLineCommentsAfter(prevTypeInfo.typeToken, config.emptyLines.lineCommentsBetweenTypes);
			prevTypeInfo = newTypeInfo;
		}
	}

	function getTypeInfo(token:TokenTree):TypeEmptyLinesInfo {
		var info:TypeEmptyLinesInfo = {
			lastToken: TokenTreeCheckUtils.getLastToken(token),
			typeToken: token,
			oneLine: false
		};
		if (isSameLine(token, info.lastToken)) {
			info.oneLine = true;
		}
		var atToken:Null<TokenTree> = token.access().firstChild().isCIdent().firstOf(At).token;
		if (atToken != null) {
			if (!isSameLine(atToken, info.lastToken)) {
				info.oneLine = false;
			}
		}
		while (true) {
			var next:Null<TokenInfo> = getNextToken(info.lastToken);
			if (next == null) {
				break;
			}
			switch (next.token.tok) {
				case Sharp(MarkLineEnds.SHARP_END):
					info.lastToken = next.token;
				default:
					break;
			}
		}
		return info;
	}

	function markLeftCurly() {
		var brOpens:Array<TokenTree> = parsedCode.root.filter([BrOpen], ALL);
		for (br in brOpens) {
			emptyLinesAfter(br, 0);
		}
	}

	function markRightCurly() {
		var brCloses:Array<TokenTree> = parsedCode.root.filter([BrClose], ALL);
		for (br in brCloses) {
			emptyLinesBefore(br, 0);
		}
	}

	function markReturn() {
		var returns:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdReturn)], ALL);
		for (ret in returns) {
			var lastChild:TokenTree = TokenTreeCheckUtils.getLastToken(ret);
			if (lastChild == null) {
				continue;
			}
			var next:Null<TokenInfo> = getNextToken(lastChild);
			if (next == null) {
				continue;
			}
			switch (next.token.tok) {
				case BrClose:
					emptyLinesAfterSubTree(ret, 0);
				default:
			}
		}
	}

	function markSharp() {
		var sharps:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Sharp(_):
					FOUND_GO_DEEPER;
				default:
					GO_DEEPER;
			}
		});
		for (sharp in sharps) {
			var prev:Null<TokenInfo> = getPreviousToken(sharp);
			if ((prev != null) && (prev.whitespaceAfter != Newline)) {
				continue;
			}
			switch (sharp.tok) {
				case Sharp(MarkLineEnds.SHARP_IF):
					emptyLinesAfterSubTree(sharp.getFirstChild(), config.emptyLines.conditionalsEmptyLines.afterIf);
				case Sharp(MarkLineEnds.SHARP_ELSE_IF):
					emptyLinesBefore(sharp, config.emptyLines.conditionalsEmptyLines.beforeElse);
					emptyLinesAfterSubTree(sharp.getFirstChild(), config.emptyLines.conditionalsEmptyLines.afterIf);
				case Sharp(MarkLineEnds.SHARP_ELSE):
					emptyLinesBefore(sharp, config.emptyLines.conditionalsEmptyLines.beforeElse);
					emptyLinesAfter(sharp, config.emptyLines.conditionalsEmptyLines.afterElse);
				case Sharp(MarkLineEnds.SHARP_END):
					emptyLinesBefore(sharp, config.emptyLines.conditionalsEmptyLines.beforeEnd);
				case Sharp(MarkLineEnds.SHARP_ERROR):
					emptyLinesBefore(sharp, config.emptyLines.conditionalsEmptyLines.beforeError);
					emptyLinesAfterSubTree(sharp, config.emptyLines.conditionalsEmptyLines.afterError);
				default:
			}
		}
	}

	function markDocComments() {
		var comments:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Comment(text):
					if (text.startsWith("*")) FOUND_GO_DEEPER; else GO_DEEPER;
				default:
					GO_DEEPER;
			}
		});
		for (comment in comments) {
			var effectiveToken:Null<TokenTree> = null;
			effectiveToken = comment;
			if (comment.previousSibling != null) {
				if ((comment.parent != null) && (comment.parent.tok != null)) {
					switch (comment.parent.tok) {
						case Sharp(_):
							if (comment.parent.getFirstChild() == comment.previousSibling) {
								effectiveToken = comment.parent;
							}
						default:
					}
				}
			} else {
				if ((comment.parent == null) || (comment.parent.tok == null)) {
					continue;
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
			switch (config.emptyLines.beforeDocCommentEmptyLines) {
				case Ignore:
				case None:
					emptyLinesBefore(effectiveToken, 0);
				case One:
					emptyLinesBefore(effectiveToken, 1);
			}
		}
	}

	function markMultilineComments() {
		var comments:Array<TokenTree> = parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			return switch (token.tok) {
				case Comment(text):
					FOUND_SKIP_SUBTREE;
				default:
					GO_DEEPER;
			}
		});
		for (comment in comments) {
			var sibling:Null<TokenTree> = comment.nextSibling;
			if (sibling == null) {
				continue;
			}
			if (!isNewLineAfter(comment)) {
				continue;
			}
			switch (sibling.tok) {
				case Comment(s):
					emptyLinesAfter(comment, config.emptyLines.betweenMultilineComments);
				default:
					continue;
			}
		}
	}

	function markAroundBlocks() {
		parsedCode.root.filterCallback(function(token:TokenTree, index:Int):FilterResult {
			switch (token.tok) {
				case Kwd(KwdIf):
					removeEmptyLinesAroundBlock(token.children[1], config.emptyLines.beforeBlocks, Keep);
					var block:Null<TokenTree> = token.access().firstOf(Kwd(KwdElse)).previousSibling().token;
					if (block != null) {
						removeEmptyLinesAroundBlock(block, Keep, config.emptyLines.afterBlocks);
					}
				case Kwd(KwdElse):
					removeEmptyLinesAroundBlock(token.getFirstChild(), config.emptyLines.beforeBlocks, Keep);
				case Kwd(KwdCase), Kwd(KwdDefault):
					var block:Null<TokenTree> = token.access().firstOf(DblDot).firstChild().token;
					removeEmptyLinesAroundBlock(block, config.emptyLines.beforeBlocks, Keep);
				case Kwd(KwdFunction):
				case Kwd(KwdFor):
					removeEmptyLinesAroundBlock(token.children[1], config.emptyLines.beforeBlocks, Keep);
				case Kwd(KwdDo):
					removeEmptyLinesAroundBlock(token.getFirstChild(), config.emptyLines.beforeBlocks, Keep);
					var block:Null<TokenTree> = token.access().lastChild().previousSibling().token;
					removeEmptyLinesAroundBlock(block, Keep, config.emptyLines.afterBlocks);
				case Kwd(KwdWhile):
					if ((token.parent == null) || (!token.parent.is(Kwd(KwdDo)))) {
						removeEmptyLinesAroundBlock(token.children[1], config.emptyLines.beforeBlocks, Keep);
					}
				case Kwd(KwdTry):
					removeEmptyLinesAroundBlock(token.getFirstChild(), config.emptyLines.beforeBlocks, Keep);
					var block:Null<TokenTree> = token.access().lastChild().previousSibling().token;
					removeEmptyLinesAroundBlock(block, Keep, config.emptyLines.afterBlocks);
				case Kwd(KwdCatch):
					removeEmptyLinesAroundBlock(token.children[1], config.emptyLines.beforeBlocks, Keep);
				default:
			}
			return GO_DEEPER;
		});
	}

	function removeEmptyLinesAroundBlock(block:TokenTree, before:KeepEmptyLinesPolicy, after:KeepEmptyLinesPolicy) {
		if (block == null) {
			return;
		}
		if (before == Remove) {
			var prev:Null<TokenInfo> = getPreviousToken(block);
			if (prev != null) {
				emptyLinesAfter(prev.token, 0);
			}
		}
		if (after == Remove) {
			emptyLinesAfterSubTree(block, 0);
		}
	}

	function keepExistingEmptyLines() {
		var funcs:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdFunction)], ALL);
		for (func in funcs) {
			var block:Null<TokenTree> = func.access().firstChild().is(BrOpen).token;
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
				var tokenInf:Null<TokenInfo> = findTokenAtOffset(idx.l);
				if (tokenInf == null) {
					continue;
				}
				if (TokenTreeCheckUtils.isMetadata(tokenInf.token)) {
					continue;
				}
				tokenInf.emptyLinesAfter++;
			}
		}
	}

	function markFileHeader() {
		var info:Null<TokenInfo> = getTokenAt(0);
		var info2:Null<TokenInfo> = getTokenAt(1);
		var packagesAndImports:Array<TokenTree> = parsedCode.root.filter([Kwd(KwdPackage), Kwd(KwdImport), Kwd(KwdUsing)], ALL);

		if (info == null) {
			return;
		}
		switch (info.token.tok) {
			case Comment(s):
				if (packagesAndImports.length == 0) {
					switch (info2.token.tok) {
						case Comment(s):
						default:
							return;
					}
				}
				info.emptyLinesAfter = config.emptyLines.afterFileHeaderComment;
			default:
		}
	}
}

typedef ImportPackageInfo = {
	var token:TokenTree;
	var isImport:Bool;
	var firstLevelPackage:String;
	var secondLevelPackage:String;
	var thirdLevelPackage:String;
	var fourthLevelPackage:String;
	var fifthLevelPackage:String;
	var fullPackage:String;
	var moduleName:String;
}

typedef TypeEmptyLinesInfo = {
	var lastToken:TokenTree;
	var typeToken:TokenTree;
	var oneLine:Bool;
}
