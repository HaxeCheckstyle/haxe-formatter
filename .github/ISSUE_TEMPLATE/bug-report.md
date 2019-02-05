---
name: Bug report
about: Create a testcase to help us improve formatter

---

**Describe the bug**<br/>
A clear and concise description of what the bug is.

**Input file**
```haxe
class Main {
	static function main() {
		doSomething("");
	}
}
```

**Broken output**
```haxe
class Main {
static function main() {
doSomething("");
}
}
```

**Expected output**
```haxe
class Main {
	static function main() {
		doSomething("");
	}
}
```

**Optional: hxformat.json**<br/>
```json
{
}
```
