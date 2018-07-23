package formatter.marker;

import formatter.codedata.CodeLine;
import formatter.codedata.CodeLines;
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

		token = findEffectiveParent(token);
		return calcFromCandidates(token);
	}

	function findEffectiveParent(token:TokenTree):TokenTree {
		switch (token.tok) {
			case BrOpen:
				var parent:TokenTree = token.parent;
				switch (parent.tok) {
					case Kwd(KwdIf), Kwd(KwdElse):
						return findEffectiveParent(token.parent);
					case Kwd(KwdCatch):
						return findEffectiveParent(token.parent);
					case Kwd(KwdDo), Kwd(KwdWhile):
						return findEffectiveParent(token.parent);
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
				if ((parent != null) && (parent.is(Kwd(KwdDo)))) {
					return findEffectiveParent(token.parent);
				}
			default:
		}
		return token;
	}

	function calcFromCandidates(token:TokenTree):Int {
		var indentingTokensCandidates:Array<TokenTree> = findIndentingCandidates(token);
		if (indentingTokensCandidates.length <= 0) {
			return 0;
		}
		var indentingTokens:Array<TokenTree> = [];
		var prevToken:TokenTree = indentingTokensCandidates.shift();
		if (!redundantIndentation(token, prevToken)) {
			indentingTokens.push(prevToken);
		} else {
			prevToken = indentingTokensCandidates.shift();
			indentingTokens.push(prevToken);
		}
		if (indentingTokensCandidates.length <= 0) {
			return indentingTokens.length;
		}
		while (indentingTokensCandidates.length > 0) {
			var currentToken:TokenTree = indentingTokensCandidates.shift();
			if (redundantIndentation(prevToken, currentToken)) {
				prevToken = currentToken;
				continue;
			}
			prevToken = currentToken;
			indentingTokens.push(prevToken);
		}
		return indentingTokens.length;
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
			case BrOpen, BkOpen, POpen:
				return true;
			case Binop(OpAssign):
				if (token.children.length == 1) {
					return false;
				}
				return true;
			case DblDot:
				if ((token.parent.is(Kwd(KwdCase))) || (token.parent.is(Kwd(KwdDefault)))) {
					return true;
				}
			case Sharp(_):
				if (config.conditionalPolicy == AlignedIncrease) {
					return true;
				}
			case Kwd(KwdIf):
				var body:TokenTree = token.access().firstOf(POpen).nextSibling().token;
				if (body == null) {
					return false;
				}
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
			default:
		}
		return false;
	}

	function redundantIndentation(prev:TokenTree, current:TokenTree):Bool {
		var tokenInfo:TokenInfo = parsedCode.tokenList.getTokenAt(current.index);
		switch (current.tok) {
			case POpen:
				switch (prev.tok) {
					case POpen, BrOpen, BkOpen:
						return true;
					default:
				}
			case BkOpen:
				switch (prev.tok) {
					case POpen, BrOpen, BkOpen:
						return true;
					case Kwd(KwdFor):
						return true;
					default:
				}
			case BrOpen:
				if (!isIndentingToken(prev)) {
					return false;
				}
				if (tokenInfo.whitespaceAfter != Newline) {
					return true;
				}
				switch (prev.tok) {
					case BkOpen:
						return true;
					default:
				}
			case Binop(OpAssign):
				switch (prev.tok) {
					case POpen, BrOpen, BkOpen:
						return true;
					case Kwd(KwdIf):
						return true;
					default:
				}
			case Kwd(KwdIf):
				switch (prev.tok) {
					case BrOpen, DblDot:
						return true;
					case Kwd(KwdIf):
						return true;
					case Kwd(KwdElse):
						return true;
					default:
				}
			case Kwd(KwdElse):
				if (tokenInfo.whitespaceAfter == Newline) {
					return false;
				}
				switch (prev.tok) {
					case BrOpen, DblDot:
						return true;
					case Kwd(KwdIf):
						return true;
					default:
				}
			case Kwd(KwdTry), Kwd(KwdFor), Kwd(KwdDo), Kwd(KwdWhile):
				switch (prev.tok) {
					case BrOpen:
						return true;
					default:
				}
			default:
		}
		return false;
	}

	public function finalRun(codeLines:CodeLines) {}
}
