package formatter.codedata;

typedef TokenInfo = {
	var token:TokenTree;
	var whitespaceAfter:WhitespaceAfterType;
	var whitespaceAfterWithoutNL:WhitespaceAfterType;
	var emptyLinesAfter:Int;
	var wrapAfter:Bool;
	var text:String;
	var additionalIndent:Int;
}
