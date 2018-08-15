package formatter.marker;

#if debugIndent
import haxe.PosInfos;
import sys.io.File;
import sys.io.FileOutput;
#end
import formatter.config.IndentationConfig;

class Indenter {
	var config:IndentationConfig;
	var parsedCode:ParsedCode;

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
		return indent;
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
		log(token, "------");
		#end
		token = findEffectiveParent(token);
		#if debugIndent
		log(token, "effectiveParent");
		#end
		return calcFromCandidates(token);
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
					case Binop(OpAssign):
						var access:TokenTreeAccessHelper = parent.access().parent().parent().is(Kwd(KwdTypedef));
						if (access.exists()) {
							return access.token;
						}
					default:
				}
			case BrClose, BkClose, PClose:
				return findEffectiveParent(token.parent);
			case Kwd(KwdIf):
				var prev:TokenInfo = parsedCode.tokenList.getPreviousToken(token);
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
						return findEffectiveParent(token.parent);
					default:
				}
			case CommentLine(_):
				var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
				if (next == null) {
					return token;
				}
				switch (next.token.tok) {
					case Kwd(KwdElse):
						return findEffectiveParent(next.token);
					default:
						return token;
				}
			default:
		}
		return token;
	}

	function setupCalcFromCandidates(token:TokenTree, prevToken:TokenTree, indentingTokensCandidates:Array<TokenTree>):Array<TokenTree> {
		var indentingTokens:Array<TokenTree> = [];
		if (!isIndentingToken(token)) {
			if (!parsedCode.tokenList.isSameLine(prevToken, token)) {
				indentingTokens.push(prevToken);
			}
			return indentingTokens;
		}
		if (prevToken.is(POpen) && token.is(BrOpen)) {
			var info:TokenInfo = parsedCode.tokenList.getTokenAt(token.index);
			if (info.whitespaceAfter != Newline) {
				indentingTokens.push(prevToken);
			}
			return indentingTokens;
		}
		if (!parsedCode.tokenList.isSameLine(prevToken, token)) {
			indentingTokens.push(prevToken);
			return indentingTokens;
		}
		indentingTokensCandidates.unshift(prevToken);
		prevToken = token;
		return indentingTokens;
	}

	function calcFromCandidates(token:TokenTree):Int {
		var indentingTokensCandidates:Array<TokenTree> = findIndentingCandidates(token);
		#if debugIndent
		log(token, "candidates: " + indentingTokensCandidates);
		#end
		if (indentingTokensCandidates.length <= 0) {
			return 0;
		}
		var prevToken:TokenTree = indentingTokensCandidates.shift();
		var indentingTokens:Array<TokenTree> = setupCalcFromCandidates(token, prevToken, indentingTokensCandidates);

		while (indentingTokensCandidates.length > 0) {
			var currentToken:TokenTree = indentingTokensCandidates.shift();
			switch (prevToken.tok) {
				case Kwd(KwdElse):
					if (currentToken.is(Kwd(KwdIf))) {
						prevToken = currentToken;
						continue;
					}
				case Kwd(KwdCatch):
					if (currentToken.is(Kwd(KwdTry))) {
						prevToken = currentToken;
						continue;
					}
				case Kwd(KwdFunction):
					if (currentToken.is(POpen)) {
						prevToken = currentToken;
						continue;
					}
				case Dot:
					switch (currentToken.tok) {
						case Dot:
							prevToken = currentToken;
							continue;
						default:
					}
				case BrOpen:
					switch (currentToken.tok) {
						case Kwd(KwdIf), Kwd(KwdElse), Kwd(KwdTry), Kwd(KwdCatch), Kwd(KwdDo), Kwd(KwdWhile), Kwd(KwdFor), Kwd(KwdFunction), Kwd(KwdSwitch):
							var type:BrOpenType = TokenTreeCheckUtils.getBrOpenType(prevToken);
							switch (type) {
								case OBJECTDECL:
								default:
									prevToken = currentToken;
									continue;
							}
						case POpen:
							var child:TokenTree = currentToken.getFirstChild();
							if (child.index != prevToken.index) {
								return calcFromCandidates(child) + indentingTokens.length;
							}
							prevToken = currentToken;
							continue;
						case Binop(OpAssign):
							if (currentToken.access().parent().parent().is(Kwd(KwdTypedef)).exists()) {
								prevToken = currentToken;
								continue;
							}
						default:
					}
				case DblDot:
					switch (currentToken.tok) {
						case Kwd(KwdCase), Kwd(KwdDefault):
							prevToken = currentToken;
							continue;
						default:
					}
				default:
			}
			if (!mustIndent(currentToken, prevToken)) {
				prevToken = currentToken;
				continue;
			}
			indentingTokens.push(currentToken);
			prevToken = currentToken;
		}
		#if debugIndent
		log(token, "final: " + indentingTokens);
		#end
		return indentingTokens.length;
	}

	function mustIndent(currentToken:TokenTree, prevToken:TokenTree):Bool {
		switch (currentToken.tok) {
			case DblDot:
				return true;
			default:
		}
		return !parsedCode.tokenList.isSameLine(prevToken, currentToken);
	}

	function findIndentingCandidates(token:TokenTree):Array<TokenTree> {
		var indentingTokensCandidates:Array<TokenTree> = [];
		var parent:TokenTree = token;
		while ((parent.parent != null) && (parent.parent.tok != null)) {
			parent = parent.parent;
			if (parent.pos.min > token.pos.min) {
				continue;
			}
			if (isIndentingToken(parent)) {
				indentingTokensCandidates.push(parent);
			}
		}
		return indentingTokensCandidates;
	}

	function isIndentingToken(token:TokenTree):Bool {
		if (token == null) {
			return false;
		}
		switch (token.tok) {
			case BrOpen, BkOpen, POpen, Dot:
				return true;
			case Binop(OpAssign):
				return true;
			case Binop(OpLt):
				return TokenTreeCheckUtils.isTypeParameter(token);
			case DblDot:
				if ((token.parent.is(Kwd(KwdCase))) || (token.parent.is(Kwd(KwdDefault)))) {
					return true;
				}
			case Sharp(_):
				if (config.conditionalPolicy == AlignedIncrease) {
					return true;
				}
			case Kwd(KwdIf):
				return true;
			case Kwd(KwdElse):
				return true;
			case Kwd(KwdFor):
				return true;
			case Kwd(KwdDo):
				return true;
			case Kwd(KwdWhile):
				var parent:TokenTree = token.parent;
				if ((parent != null) && (parent.is(Kwd(KwdDo)))) {
					return false;
				}
				return true;
			case Kwd(KwdTry):
				return true;
			case Kwd(KwdCatch):
				return true;
			case Kwd(KwdFunction):
				return true;
			case Kwd(KwdReturn):
				return true;
			case Kwd(KwdUntyped):
				return true;
			case Kwd(KwdSwitch), Kwd(KwdCase), Kwd(KwdDefault):
				return true;
			case Kwd(KwdThrow):
				return true;
			default:
		}
		return false;
	}

	#if debugIndent
	function log(token:TokenTree, what:String, ?pos:PosInfos) {
		var text:String = '`${token}` - $what - ${pos.fileName}:${pos.lineNumber}';
		var file:FileOutput = File.append("hxformat.log", false);
		file.writeString(text + "\n");
		file.close();
	}
	#end
}
