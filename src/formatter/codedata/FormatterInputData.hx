package formatter.codedata;

import tokentree.TokenTreeBuilder.TokenTreeEntryPoint;
import formatter.config.Config;

typedef FormatterInputData = {
	var fileName:String;
	var content:Bytes;
	@:optional var tokenList:Array<Token>;
	@:optional var tokenTree:TokenTree;
	var config:Config;
	@:optional var entryPoint:TokenTreeEntryPoint;
	@:optional var lineSeparator:String;
	@:optional var range:FormatterInputRange;
}

typedef FormatterInputRange = {
	var startPos:Int;
	var endPos:Int;
}
