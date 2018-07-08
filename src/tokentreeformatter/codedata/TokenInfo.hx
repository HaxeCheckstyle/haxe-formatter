package tokentreeformatter.codedata;

typedef TokenInfo = {
	var token:TokenTree;
	var whitespaceAfter:WhitespaceAfterType;
	var emptyLinesAfter:Int;
	var wrapAfter:Bool;
	var text:String;
}