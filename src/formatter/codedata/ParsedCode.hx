package formatter.codedata;

import haxeparser.HaxeLexer;
import tokentree.TokenTreeBuilder;

class ParsedCode {
	static inline var BAD_OFFSET:String = "Bad offset";

	public var file(default, null):ParseFile;
	public var tokens(default, null):Array<Token>;
	public var linesIdx(default, null):Array<LineIds>;
	public var lines(default, null):Array<String>;
	public var lineSeparator(default, null):String;
	public var root(default, null):TokenTree;
	public var tokenList(default, null):TokenList;
	public var emptyLines(default, null):Array<Int>;

	public function new(file:ParseFile, ?tokenData:TokenData) {
		this.file = file;
		try {
			removeBOM();
			detectLineSeparator();
			makeLines();
			makePosIndices();
			if (tokenData == null) {
				makeTokens();
				getTokenTree();
			} else {
				tokens = tokenData.tokens;
				root = tokenData.tokenTree;
				makeTokenList();
			}
		} catch (e:Any) {
			throw 'failed to create parser context $e';
		}
	}

	public function getTokenTree():TokenTree {
		if (tokens == null) {
			return null;
		}
		if (root == null) {
			root = TokenTreeBuilder.buildTokenTree(tokens, ByteData.ofBytes(file.content));
			makeTokenList();
		}
		return root;
	}

	function removeBOM() {
		if (file.content == null) {
			return;
		}
		if (file.content.get(0) != 0xEF) {
			return;
		}
		if (file.content.get(1) != 0xBB) {
			return;
		}
		if (file.content.get(2) != 0xBF) {
			return;
		}
		var withBOM:Bytes = file.content;
		file.content = withBOM.sub(3, file.content.length - 3);
	}

	function makeTokenList() {
		tokenList = new TokenList();
		tokenList.buildList(root);
	}

	function makePosIndices() {
		var code:Bytes = file.content;
		linesIdx = [];

		var last = 0;
		var left = false;

		for (i in 0...code.length) {
			if (code.get(i) == 0x0A) {
				linesIdx.push({l: last, r: i});
				last = i + 1;
				left = false;
			}
			left = true;
		}
		if (left) {
			linesIdx.push({l: last, r: code.length});
		}
	}

	public function getLinePos(off:Int):LinePos {
		var lowerBound:Int = 0;
		var upperBound:Int = linesIdx.length - 1;
		if (linesIdx.length <= 0) {
			throw BAD_OFFSET;
		}

		if (off < 0) {
			throw BAD_OFFSET;
		}

		if (off > linesIdx[upperBound].r) {
			throw BAD_OFFSET;
		}

		while (true) {
			if (lowerBound > upperBound) {
				throw BAD_OFFSET;
			}

			var center:Int = lowerBound + Math.floor((upperBound - lowerBound) / 2);
			var matchLeft:Bool = linesIdx[center].l <= off;
			var matchRight:Bool = linesIdx[center].r >= off;
			if (matchLeft && matchRight) {
				return {line: center, ofs: off - linesIdx[center].l};
			}
			if (matchLeft) {
				lowerBound = center + 1;
				continue;
			}
			if (matchRight) {
				upperBound = center - 1;
				continue;
			}
		}
		throw BAD_OFFSET;
	}

	public function getString(off:Int, off2:Int):String {
		var code:Bytes = file.content;
		var len:Int = off2 - off;
		if ((off >= code.length) || (off + len > code.length)) {
			return "";
		}
		return code.sub(off, off2 - off).toString();
	}

	function detectLineSeparator() {
		var codeBytes:Bytes = file.content;
		var code:String = codeBytes.toString();

		for (i in 0...code.length) {
			var char = code.charAt(i);
			if ((char == "\r") || (char == "\n")) {
				lineSeparator = char;
				if ((char == "\r") && (i + 1 < code.length)) {
					char = code.charAt(i + 1);
					if (char == "\n") {
						lineSeparator += char;
					}
				}
				return;
			}
		}

		// default
		lineSeparator = "\n";
	}

	#if false
	function makeLines() {
		var code:Bytes = file.content;
		var textCode:String = code.toString();
		lines = textCode.split(lineSeparator);
	}
	#end

	function makeLines() {
		var code:Bytes = file.content;
		var textCode:String = code.toString();
		lines = textCode.split(lineSeparator);

		emptyLines = [];
		for (index in 0...lines.length) {
			var line:String = lines[index];
			if (~/^\s*$/.match(line)) {
				emptyLines.push(index);
			}
		}
	}

	function makeTokens() {
		try {
			tokens = [];
			root = null;
			var lexer = new HaxeLexer(ByteData.ofBytes(file.content), file.name);
			var t:Token = lexer.token(haxeparser.HaxeLexer.tok);

			while (t.tok != Eof) {
				tokens.push(t);
				t = lexer.token(haxeparser.HaxeLexer.tok);
			}
		} catch (e:Any) {
			throw 'failed to make tokens $e';
		}
	}
}

typedef LinePos = {
	var line:Int;
	var ofs:Int;
}

typedef LineIds = {
	var l:Int;
	var r:Int;
}
