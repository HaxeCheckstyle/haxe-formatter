package testcases;

class OperatorWhitespaceText extends GoldBaseTest {
	@Test
	public function testTernary() {
		goldCheckExpr("true ? 0 : 1;", "true ? 0 : 1;");
	}
}