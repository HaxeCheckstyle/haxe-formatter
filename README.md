# Haxe Formatter

[![Build Status](https://travis-ci.org/HaxeCheckstyle/haxe-formatter.svg?branch=master)](https://travis-ci.org/HaxeCheckstyle/haxe-formatter)
[![codecov](https://codecov.io/gh/HaxeCheckstyle/haxe-formatter/branch/master/graph/badge.svg)](https://codecov.io/gh/HaxeCheckstyle/haxe-formatter)


**use at your own risk**

Formatter based on tokentree library

**make a backup of your files and use a diff tool**

## Features
- Indentation
- Whitespace
- Wrapping
  - arrays
  - object literals
  - anonymous types
  - long lines
- EmptyLines
  - abstract
  - enum abstract
  - class
  - extern class
  - interface
  - enum
  - typedef
- SameLine
  - if
  - loops
  - try / catch
  - objects / anonymous types
- LineEnds
- `hxformat.json` config file
- supports `// @formatter:off` and `// @formatter:on` to preserve hand crafted format of code sections
- unittests
  - format self
  - easy testcase definition through .hxtest files

## How to use

### Bulk formatting
Run `haxelib run formatter -s src` to format folder src.
Run `haxelib run formatter -s src -s test` to format folders src and test.

Formatter also comes with a NodeJS version which is generally faster when formatting medium to large code bases. Run with `node <path/to/haxelib/formatter>/run.js -s src`to format folder src

### Single file formatting
Run `haxelib run formatter -s src/Main.hx` to format file `src/Main.hx`.

### Format check
Use `--check` to run formatter in check mode to see if code is properly formatted without modifying it.

### VSCode extension
To enable formatter on VSCode add
```
	"[haxe]": {
		"editor.formatOnSave":true
	}
```
or
```
  "editor.formatOnSave":true
```
to your settings.

## Configuration

Formatter uses `hxformat.json` files for configuration.
Formatter searches for a `hxformat.json` file closest to the file being formatted. Starting with the file's folder and moving upward all the way to your root folder. Formatter will stop looking at the first configuration file it finds. A configuration file in a subfolder will always overwrite any settings from a top or higher level folder.

The VSCode extension comes with a JSON schema providing completion and limited documentation for edition `hxformat.json` files.

An empty `hxformat.json` (containing only `{}`) or having `hxformat.json` will result in formatting using the built-in default which is the coding style of formatter itself.

When creating your custom `hxformat.json` file, you only need to provide settings that you want to override with respect to the built-in default. So configuration always starts with the default style of formatter.

### Ways to opt-out of formatting
1. turn off formatter in your IDE / don't run CLI version
  - affects all files
2. place a `hxformat.json` file with `{ "disableFormatting": true }` in you workspace
  - affects all files and subfolders from where you placed `hxformat.json`
  - since formatter searches for a `hxformat.json` file closest to the file being formatted, you can `disableFormatting` in a subfolder, while enabling it everywhere else
  - you can reverse a `disableFormatting` by placing a `hxformat.json` with `{}` (for built-in formatter config) in a subfolder, every file in that subfolder and below will get formatted
3. use `excludes` inside your `hxformat.json` to specify a number of regexes, that will exclude any filename from formatting matching any one of these regexes
4. use `// @formatter:off` and `// @formatter:on` comments inside your code to turn off formatting for parts of your code, it's line based and includes lines containing `// @formatter:off` and `// @formatter:on`.


## ToDo
- improve wrapping
