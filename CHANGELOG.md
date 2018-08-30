## dev branch / next version (1.x.x)

- Added `Keep` to SameLinePolicy [#226](https://github.com/HaxeCheckstyle/haxe-formatter/issues/226
- Added `emptyLines.classEmptyLines.endType` to output empty lines before end of classes
- Added `emptyLines.abstractEmptyLines.endType` to output empty lines before end of abstracts
- Added `emptyLines.enumAbstractEmptyLines.endType` to output empty lines before end of enum abstracts
- Added `emptyLines.externClassEmptyLines.endType` to output empty lines before end of extern classes
- Added `emptyLines.interfaceEmptyLines.endType` to output empty lines before end of interfaces
- Added `emptyLines.enumEmptyLines.endType` to output empty lines before end of enums
- Added `emptyLines.typedefEmptyLines.endType` to output empty lines before end of typedefs
- Added `indentation.trailingWhitespace` to output trailing whitespace in empty lines
- Added `--default-config` CLI option to generate a default "hxformat.json"
- Changed `whitespace.closingBracePolicy` to `after`
- Changed `whitespace.typeExtensionPolicy` to `after`
- Changed `whitespace.semicolonPolicy` to `onlyAfter`
- Fixed indentation of else with object literal body, fixes [#220](https://github.com/HaxeCheckstyle/haxe-formatter/issues/220) ([#224](https://github.com/HaxeCheckstyle/haxe-formatter/issues/224))
- Fixed indentation of prefix unary, fixes [#221](https://github.com/HaxeCheckstyle/haxe-formatter/issues/221) ([#224](https://github.com/HaxeCheckstyle/haxe-formatter/issues/224))
- Fixed whitespace after macro reification, fixes [#218](https://github.com/HaxeCheckstyle/haxe-formatter/issues/218) + [#219](https://github.com/HaxeCheckstyle/haxe-formatter/issues/219) ([#225](https://github.com/HaxeCheckstyle/haxe-formatter/issues/225))
- Fixed type check on numbers, fixes [#217](https://github.com/HaxeCheckstyle/haxe-formatter/issues/217) ([#225](https://github.com/HaxeCheckstyle/haxe-formatter/issues/225))
- Refactored Space and Newline handling of MarkWhitespace

## version 1.0.0 (2018-08-20)

- initial release
