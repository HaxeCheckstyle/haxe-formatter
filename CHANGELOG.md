## dev branch / next version (1.x.x)

- Fixed version number reported on CLI
- Fixed handling of macro blocks
- Changed default rules for function signature

## version 1.1.0 (2018-09-04)

- **Breakin Change** added a default wrap type for wrapping rules [#230](https://github.com/HaxeCheckstyle/haxe-formatter/issues/230)
- Added `Keep` to SameLinePolicy [#226](https://github.com/HaxeCheckstyle/haxe-formatter/issues/226)
- Added `emptyLines.classEmptyLines.endType` to output empty lines before end of classes [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Added `emptyLines.abstractEmptyLines.endType` to output empty lines before end of abstracts [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Added `emptyLines.enumAbstractEmptyLines.endType` to output empty lines before end of enum abstracts [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Added `emptyLines.externClassEmptyLines.endType` to output empty lines before end of extern classes [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Added `emptyLines.interfaceEmptyLines.endType` to output empty lines before end of interfaces [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Added `emptyLines.enumEmptyLines.endType` to output empty lines before end of enums [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Added `emptyLines.typedefEmptyLines.endType` to output empty lines before end of typedefs [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Added `indentation.trailingWhitespace` to output trailing whitespace in empty lines [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Added `--default-config` CLI option to generate a default "hxformat.json" [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Added `wrapping.methodChaining` to handle wrapping of method chains [#229](https://github.com/HaxeCheckstyle/haxe-formatter/issues/229)
- Changed `whitespace.closingBracePolicy` to `after` [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Changed `whitespace.typeExtensionPolicy` to `after` [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Changed `whitespace.semicolonPolicy` to `onlyAfter` [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)
- Fixed indentation of else with object literal body, fixes [#220](https://github.com/HaxeCheckstyle/haxe-formatter/issues/220) ([#224](https://github.com/HaxeCheckstyle/haxe-formatter/issues/224))
- Fixed indentation of prefix unary, fixes [#221](https://github.com/HaxeCheckstyle/haxe-formatter/issues/221) ([#224](https://github.com/HaxeCheckstyle/haxe-formatter/issues/224))
- Fixed whitespace after macro reification, fixes [#218](https://github.com/HaxeCheckstyle/haxe-formatter/issues/218) + [#219](https://github.com/HaxeCheckstyle/haxe-formatter/issues/219) ([#225](https://github.com/HaxeCheckstyle/haxe-formatter/issues/225))
- Fixed type check on numbers, fixes [#217](https://github.com/HaxeCheckstyle/haxe-formatter/issues/217) ([#225](https://github.com/HaxeCheckstyle/haxe-formatter/issues/225))
- Fixed typedefs without assign, fixes [#228](https://github.com/HaxeCheckstyle/haxe-formatter/issues/228) ([#229](https://github.com/HaxeCheckstyle/haxe-formatter/issues/229))
- Refactored Space and Newline handling of MarkWhitespace [#227](https://github.com/HaxeCheckstyle/haxe-formatter/issues/227)

## version 1.0.0 (2018-08-20)

- initial release
