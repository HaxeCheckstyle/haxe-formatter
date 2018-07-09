package tokentreeformatter.config;

class Config {
	public var emptylines:EmptyLinesConfig;
	public var indentation:IndentationConfig;
	public var lineEnds:LineEndConfig;
	public var whitespace:WhitespaceConfig;
	public var wrapping:WrapConfig;

	public function new() {
		emptylines = {
			afterPackage: 2,
			afterImportsUsing: 1,
			betweenTypes: 1,
			anywhereInFileMax: 1,
			betweenClassFunctions: 1
		};
		indentation = {
			conditionalPolicy: ALIGNED,
			character: "tab"
		};
		lineEnds = {
			at: AFTER,
			sharp: AFTER,
			leftCurly: AFTER,
			rightCurly: BOTH
		};
		whitespace = {
			pOpenPolicy: NONE_AFTER,
			pClosePolicy: NONE,
			bkOpenPolicy: NONE_AFTER,
			bkClosePolicy: NONE,
			brOpenPolicy: BEFORE,
			brClosePolicy: AROUND,
			typeParamOpenPolicy: NONE,
			typeParamClosePolicy: NONE,
			commaPolicy: AFTER,
			dotPolicy: NONE,
			semicolonPolicy: NONE,
			binopPolicy: AROUND,
			ifPolicy: AFTER,
			doPolicy: AFTER,
			whilePolicy: AFTER,
			forPolicy: AFTER,
			functionPolicy: AFTER,
			tryPolicy: AFTER,
			catchPolicy: AFTER
		};
		wrapping = {
			maxLineLength: 120,
			wrapAfterComma: true,
			wrapBeforeDot: true,
			wrapAfterBrOpen: true,
			wrapAfterBkOpen: true
		};
	}

	public function readConfig(fileName:String) {
		// TODO implement me
	}
}