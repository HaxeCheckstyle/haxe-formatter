#!/bin/bash -e

ln -sfn haxe4_libraries haxe_libraries

npm install
npx lix download
npx lix use haxe 4.0.0-rc.5

npx haxe buildJsNode.hxml
npx haxe buildJsBrowser.hxml
npx haxe buildNeko.hxml
npx haxe buildJava.hxml
npx haxe buildSchema.hxml

neko run --default-config resources/default-hxformat.json

npx haxe test.hxml

rm -f formatter.zip
zip -9 -r -q formatter.zip src run.n run.js resources/default-hxformat.json resources/formatter-schema.json haxelib.json README.md CHANGELOG.md LICENSE.md
