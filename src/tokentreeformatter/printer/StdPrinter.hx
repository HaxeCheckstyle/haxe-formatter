package tokentreeformatter.printer;

class StdPrinter implements IPrinter {

	public function new() {}

	public function printLine(line:String) {
		Sys.println(line);
	}

	public function printEmptyLine() {
		Sys.println("");
	}
}