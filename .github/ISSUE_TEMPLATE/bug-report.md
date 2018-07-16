---
name: Bug report
about: Create a testcase to help us improve formatter

---

**Describe the bug**<br/>
A clear and concise description of what the bug is.

**Sample of expected output**
```
class Main {
	static function main() {
		doSomething("");
	}
}
```

**Sample of broken output**
```
class Main {
static function main() {
doSomething("");
}
}
```

**Provide a test case**<br/>
Sections delimited by `---`; empty lines required before and after `---`<br/>
Section 1: replace `{}` with content of your `hxformat.json` required to reproduce or leave empty for default config<br/>
Section 2: Replace with input code<br/>
Section 3: Replace with expected / gold output

```
{}

---

class Main {
	static function main() { doSomething(""); }
}

---

class Main {
	static function main() {
		doSomething("");
	}
}
```
