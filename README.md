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
  - lon lines
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
  - easy testcase definition through .hxtest

## Ways to opt-out of formatting
1. turn off formatter in your IDE
  - affects all files
2. place a `hxformat.json` file with `{ "disableFormatting": true }` in you workspace
  - affects all files and subfolders from where you placed `hxformat.json`
  - since formatter searches for a `hxformat.json` file closest to the file being formatted, you can `disableFormatting` in a subfolder, while enabling it everywhere else
  - you can reverse a `disableFormatting` by placing a `hxformat.json` with `{}` (for built-in formatter config) in a subfolder, every file in that subfolder and below will get formatted
3. use `excludes` inside your `hxformat.json` to specify a number of regexes, that will exclude any filename from formatting matching any one of these regexes
4. use `// @formatter:off` and `// @formatter:on` comments inside your code to turn off formatting for parts of your code, It's line based and includes lines containing `// @formatter:off` and `// @formatter:on`.


## ToDo
- improve wrapping

## TBD
- code modification e.g.
  - import grouping and sort
  - modifier sort
