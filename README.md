# Haxe Formatter

[![Build Status](https://travis-ci.org/HaxeCheckstyle/tokentree-formatter.svg?branch=master)](https://travis-ci.org/HaxeCheckstyle/tokentree-formatter)
[![Codecov](https://img.shields.io/codecov/c/github/HaxeCheckstyle/tokentree-formatter.svg)](https://codecov.io/github/HaxeCheckstyle/tokentree-formatter?branch=master)

**use at your own risk**

Formatter based on tokentree library

**make a backup of your files**


## Features
- Indentation
- Whitespace
- Wrapping
- EmptyLines
  - abstract
  - enum abstract
  - class
- SameLine
  - if
  - loops
  - try / catch
  - objects / anonymous types
- LineEnds
- `hxformat.json` config file

## ToDo
- Configuration
  - more options
  - load (save)
- better wrapping
  - arrays
  - objects / anonymous types
- empty lines in
  - enum
  - interface
  - typedef
- unittests
  - format self

## TBD
- import grouping and sort
- modifier sort
