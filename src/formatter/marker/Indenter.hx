package formatter.marker;

#if debugIndent
import haxe.PosInfos;
import sys.io.File;
import sys.io.FileOutput;
#end
import formatter.config.IndentationConfig;

class Indenter {
	var config:IndentationConfig;
	var parsedCode:Null<ParsedCode>;

	public function new(config:IndentationConfig) {
		this.config = config;
		if (config.character.toLowerCase() == "tab") {
			config.character = "\t";
		}
	}

	public function setParsedCode(parsedCode:ParsedCode) {
		this.parsedCode = parsedCode;
	}

	public function makeIndent(token:TokenTree):String {
		return makeIndentString(calcIndent(token));
	}

	public function makeIndentString(count:Int):String {
		return "".lpad(config.character, config.character.length * count);
	}

	public function calcAbsoluteIndent(indent:Int):Int {
		if (config.character == "\t") {
			return indent * config.tabWidth;
		}
		return indent * config.character.length;
	}

	public function calcIndent(token:TokenTree):Int {
		if (token == null) {
			return 0;
		}
		switch (token.tok) {
			case Sharp(_):
				if (config.conditionalPolicy == FixedZero) {
					return 0;
				}
			default:
		}
		#if debugIndent
		logIndentStart();
		log(token, "start");
		#end
		token = findEffectiveParent(token);
		#if debugIndent
		log(token, "effectiveParent");
		#end
		return calcFromCandidates(token);
	}

	public function shouldAddTrailingWhitespace():Bool {
		return config.trailingWhitespace;
	}

	function findEffectiveParent(token:TokenTree):TokenTree {
		if (token.tok == null) {
			return token.getFirstChild();
		}

		switch (token.tok) {
			case BrOpen:
				var parent:TokenTree = token.parent;
				if (parent.tok == null) {
					return token;
				}
				var type:BrOpenType = TokenTreeCheckUtils.getBrOpenType(token);
				switch (type) {
					case BLOCK:
					case TYPEDEFDECL:
						return token.parent;
					case OBJECTDECL:
						return token;
					case ANONTYPE:
						return token;
					case UNKNOWN:
				}
				switch (parent.tok) {
					case Kwd(KwdIf), Kwd(KwdElse):
						return findEffectiveParent(parent);
					case Kwd(KwdTry), Kwd(KwdCatch):
						return findEffectiveParent(parent);
					case Kwd(KwdDo), Kwd(KwdWhile), Kwd(KwdFor):
						return findEffectiveParent(parent);
					case Kwd(KwdFunction):
						return findEffectiveParent(parent);
					case Kwd(KwdSwitch):
						return findEffectiveParent(parent);
					case Const(CIdent(_)), Kwd(KwdNew):
						if (parent.parent.is(Kwd(KwdFunction))) {
							return findEffectiveParent(parent.parent);
						}
					case Binop(OpAssign), Binop(OpAssignOp(_)):
						var access:TokenTreeAccessHelper = parent.access().parent().parent().is(Kwd(KwdTypedef));
						if (access.exists()) {
							return access.token;
						}
					default:
				}
			case BrClose, BkClose:
				return findEffectiveParent(token.parent);
			case Arrow:
				return findEffectiveParent(token.parent);
			case PClose:
				return findEffectiveParent(token.parent);
			case Kwd(KwdIf):
				var prev:Null<TokenInfo> = parsedCode.tokenList.getPreviousToken(token);
				if (prev == null) {
					return token;
				}
				if (prev.whitespaceAfter == Newline) {
					return token;
				}
				var parent:TokenTree = token.parent;
				if (parent.tok == null) {
					return token;
				}
				switch (parent.tok) {
					case Binop(_):
						return token;
					case Kwd(KwdElse):
					case Kwd(_):
						return token;
					default:
				}
				return findEffectiveParent(token.parent);
			case Kwd(KwdElse), Kwd(KwdCatch):
				return findEffectiveParent(token.parent);
			case Kwd(KwdWhile):
				var parent:TokenTree = token.parent;
				if (parent.tok == null) {
					return token;
				}
				if ((parent != null) && (parent.is(Kwd(KwdDo)))) {
					return findEffectiveParent(token.parent);
				}
			case Kwd(KwdFunction):
				var parent:TokenTree = token.parent;
				if (parent.tok == null) {
					return token;
				}
				switch (parent.tok) {
					case POpen:
						if (parsedCode.tokenList.isNewLineBefore(token)) {
							return token;
						}
						return findEffectiveParent(token.parent);
					default:
				}
			case CommentLine(_), Comment(_):
				var next:Null<TokenInfo> = parsedCode.tokenList.getNextToken(token);
				if (next == null) {
					return token;
				}
				switch (next.token.tok) {
					case Kwd(KwdElse):
						return findEffectiveParent(next.token);
					case Kwd(KwdCatch):
						return findEffectiveParent(next.token);
					default:
						return token;
				}
			case Sharp(MarkLineEnds.SHARP_ELSE), Sharp(MarkLineEnds.SHARP_ELSE_IF), Sharp(MarkLineEnds.SHARP_END):
				return findEffectiveParent(token.parent);

			default:
		}
		return token;
	}

	function countLineBreaks(indentingTokensCandidates:Array<TokenTree>):Int {
		var count:Int = 0;
		var prevToken:Null<TokenTree> = null;
		var currentToken:Null<TokenTree> = null;
		var mustIndent:Bool;
		var lastIndentingToken:Null<TokenTree> = null;
		for (token in indentingTokensCandidates) {
			prevToken = currentToken;
			if (prevToken == null) {
				prevToken = token;
			}
			currentToken = token;
			#if debugIndent
			log(token, '"$prevToken" -> "$currentToken"');
			#end
			mustIndent = false;
			switch (prevToken.tok) {
				case Kwd(KwdIf):
					if (prevToken.index == currentToken.index) {
						continue;
					}
					if (parsedCode.tokenList.isSameLineBetween(currentToken, prevToken, false)) {
						var elseTok:Null<TokenTree> = prevToken.access().firstOf(Kwd(KwdElse)).token;
						if (elseTok != null) {
							if (parsedCode.tokenList.isSameLineBetween(prevToken, elseTok, false)) {
								continue;
							}
							mustIndent = true;
						}
					}

				case Kwd(KwdElse):
					continue;
				case Kwd(KwdCatch):
					if (currentToken.is(Kwd(KwdTry))) {
						continue;
					}
				case Kwd(KwdFunction):
					if (currentToken.is(POpen) && !parsedCode.tokenList.isNewLineAfter(currentToken)) {
						continue;
					}
				case Kwd(KwdSwitch):
					switch (currentToken.tok) {
						case POpen:
							var type:POpenType = TokenTreeCheckUtils.getPOpenType(currentToken);
							switch (type) {
								case AT:
								case PARAMETER:
									mustIndent = true;
								case CALL:
								case CONDITION:
									mustIndent = true;
								case FORLOOP:
								case EXPRESSION:
							}
						default:
					}
				case Arrow:
					if (currentToken.is(POpen)) {
						continue;
					}
				case Dot:
					switch (currentToken.tok) {
						case POpen, BrOpen:
							if (parsedCode.tokenList.isSameLine(currentToken, prevToken)) {
								continue;
							}
							mustIndent = true;
						case Dot:
							if ((prevToken.pos.min == currentToken.pos.min) && parsedCode.tokenList.isNewLineBefore(currentToken)) {
								// first dot & has a newline
							} else {
								continue;
							}
						case Binop(OpAssign), Binop(OpAssignOp(_)):
						case Kwd(KwdReturn), Kwd(KwdUntyped), Kwd(KwdNew):
							if (!parsedCode.tokenList.isNewLineBefore(prevToken)) {
								continue;
							}
						default:
							if (parsedCode.tokenList.isNewLineBefore(prevToken)) {
								#if debugIndent
								log(token, 'adds "$prevToken"');
								#end
								count++;
								continue;
							}
					}
				case BrOpen:
					switch (currentToken.tok) {
						case Kwd(KwdIf), Kwd(KwdElse), Kwd(KwdTry), Kwd(KwdCatch), Kwd(KwdDo), Kwd(KwdWhile), Kwd(KwdFor), Kwd(KwdFunction), Kwd(KwdSwitch),
							Kwd(KwdReturn):
							var type:BrOpenType = TokenTreeCheckUtils.getBrOpenType(prevToken);
							switch (type) {
								case OBJECTDECL:
									var brClose:TokenTree = prevToken.access().firstOf(BrClose).token;
									if ((brClose != null)
										&& (!parsedCode.tokenList.isSameLine(prevToken, brClose))
										&& !config.indentObjectLiteral) {
										continue;
									}
								default:
									continue;
							}
						case POpen:
							if (!parsedCode.tokenList.isNewLineBefore(prevToken)) {
								continue;
							}
						case Binop(OpAssign), Binop(OpAssignOp(_)):
							if (currentToken.access().parent().parent().is(Kwd(KwdTypedef)).exists()) {
								continue;
							}
							var type:BrOpenType = TokenTreeCheckUtils.getBrOpenType(prevToken);
							switch (type) {
								case OBJECTDECL:
									var brClose:TokenTree = prevToken.access().firstOf(BrClose).token;
									if ((brClose != null)
										&& (!parsedCode.tokenList.isSameLine(prevToken, brClose))
										&& !config.indentObjectLiteral) {
										continue;
									}
								default:
									// continue;
							}
						default:
					}
				case DblDot:
					switch (currentToken.tok) {
						case Kwd(KwdCase), Kwd(KwdDefault):
							if ((lastIndentingToken != null) && (lastIndentingToken.pos.min == prevToken.pos.min)) {
								continue;
							}
							mustIndent = true;
						default:
					}
				case Const(CIdent("from")), Const(CIdent("to")):
					if (isAbstractFromTo(token) && parsedCode.tokenList.isNewLineBefore(prevToken)) {
						mustIndent = true;
					}
				default:
			}
			if (!mustIndent && parsedCode.tokenList.isSameLineBetween(currentToken, prevToken, false)) {
				continue;
			}
			if (!isIndentingToken(currentToken)) {
				continue;
			}
			#if debugIndent
			log(token, 'adds "$currentToken"');
			#end
			lastIndentingToken = currentToken;
			count++;
		}
		return count;
	}

	function calcFromCandidates(token:TokenTree):Int {
		var indentingTokensCandidates:Array<TokenTree> = findIndentingCandidates(token);
		#if debugIndent
		log(token, "candidates: " + indentingTokensCandidates);
		#end
		if (indentingTokensCandidates.length <= 0) {
			return 0;
		}
		var count:Int = countLineBreaks(indentingTokensCandidates);
		if (hasConditional(indentingTokensCandidates)) {
			switch (config.conditionalPolicy) {
				case AlignedDecrease:
					count--;
				case AlignedIncrease:
				case FixedZero:
				case Aligned:
			}
		}
		#if debugIndent
		log(token, "final indent: " + count);
		#end
		return count;
	}

	function hasConditional(tokens:Array<TokenTree>):Bool {
		for (token in tokens) {
			switch (token.tok) {
				case Sharp("if"):
					return true;
				default:
			}
		}
		return false;
	}

	function findIndentingCandidates(token:TokenTree):Array<TokenTree> {
		var indentingTokensCandidates:Array<TokenTree> = [];
		var lastIndentingToken:Null<TokenTree> = null;
		switch (token.tok) {
			case Dot:
				lastIndentingToken = token;
			default:
		}
		indentingTokensCandidates.push(token);
		var parent:Null<TokenTree> = token;
		while ((parent.parent != null) && (parent.parent.tok != null)) {
			parent = parent.parent;
			if (parent.pos.min > token.pos.min) {
				continue;
			}
			if (isIndentingToken(parent)) {
				if (lastIndentingToken != null) {
					if (lastIndentingToken.is(Dot) && parent.is(Dot)) {
						continue;
					}
				}
				indentingTokensCandidates.push(parent);
				lastIndentingToken = parent;
			} else {
				if (parsedCode.tokenList.isNewLineBefore(parent)) {
					indentingTokensCandidates.push(parent);
					lastIndentingToken = parent;
				}
			}
		}

		var compressedCandidates:Array<TokenTree> = [];
		var state:IndentationCompressElseIf = Copy;
		for (token in indentingTokensCandidates) {
			switch (token.tok) {
				case Kwd(KwdIf):
					switch (state) {
						case Copy:
							if (token.access().firstOf(Kwd(KwdElse)).exists()) {
								state = SkipElseIf;
							}
						case SeenElse:
							state = SkipElseIf;
						case SkipElseIf:
							continue;
					}
				case Kwd(KwdElse):
					if ((state == SeenElse) || (state == SkipElseIf)) {
						state = SkipElseIf;
						continue;
					}
					state = SeenElse;
				default:
					state = Copy;
			}
			compressedCandidates.push(token);
		}
		return compressedCandidates;
	}

	function isIndentingToken(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		switch (token.tok) {
			case BrOpen, BkOpen, POpen, Dot:
				return true;
			case Binop(OpAssign), Binop(OpAssignOp(_)):
				return true;
			case Arrow:
				return true;
			case Binop(OpLt):
				return TokenTreeCheckUtils.isTypeParameter(token);
			case DblDot:
				if ((token.parent.is(Kwd(KwdCase))) || (token.parent.is(Kwd(KwdDefault)))) {
					return true;
				}
				var info:Null<TokenInfo> = parsedCode.tokenList.getTokenAt(token.index);
				if (info == null) {
					return false;
				}
				switch (info.whitespaceAfter) {
					case None, Space:
						return false;
					case Newline:
						return true;
				}
			case Sharp(MarkLineEnds.SHARP_IF):
				switch (config.conditionalPolicy) {
					case AlignedIncrease, AlignedDecrease:
						return true;
					case Aligned:
						return false;
					case FixedZero:
						return false;
				}
			case Kwd(KwdIf), Kwd(KwdElse):
				return true;
			case Kwd(KwdFor), Kwd(KwdDo):
				return true;
			case Kwd(KwdWhile):
				var parent:TokenTree = token.parent;
				if ((parent != null) && (parent.is(Kwd(KwdDo)))) {
					return false;
				}
				return true;
			case Kwd(KwdTry), Kwd(KwdCatch), Kwd(KwdThrow):
				return true;
			case Kwd(KwdFunction):
				return true;
			case Kwd(KwdReturn), Kwd(KwdUntyped):
				return true;
			case Kwd(KwdNew):
				switch (token.parent.tok) {
					case Kwd(KwdFunction):
						return false;
					default:
						return true;
				}
			case Kwd(KwdSwitch), Kwd(KwdCase), Kwd(KwdDefault):
				return true;
			case Kwd(KwdVar):
				return true;
			case Const(CIdent("from")), Const(CIdent("to")):
				return isAbstractFromTo(token);
			default:
		}
		return false;
	}

	function isAbstractFromTo(token:TokenTree):Bool {
		var parent:Null<TokenTree> = token.parent;
		if ((parent == null) || (parent.tok == null)) {
			return false;
		}
		switch (parent.tok) {
			case Const(CIdent(_)):
			default:
				return false;
		}
		parent = parent.parent;
		if ((parent == null) || (parent.tok == null)) {
			return false;
		}
		switch (parent.tok) {
			case Kwd(KwdAbstract):
				return true;
			default:
				return false;
		}
	}

	#if debugIndent
	function logIndentStart() {
		var file:FileOutput = File.append("hxformat.log", false);
		file.writeString("\n".lpad("-", 202));
		file.close();
	}

	function log(token:TokenTree, what:String, ?pos:PosInfos) {
		var tokenText:String = '`$token` (${token.pos.min})';
		var text:String = '${tokenText.rpad(" ", 50)} ${what.rpad(" ", 90)}';
		var file:FileOutput = File.append("hxformat.log", false);
		file.writeString(text + "\n");
		file.close();
	}
	#end
}

enum IndentationCompressElseIf {
	Copy;
	SeenElse;
	SkipElseIf;
}
