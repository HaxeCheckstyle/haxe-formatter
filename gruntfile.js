module.exports = function(grunt) {
    grunt.initConfig({
        pkg: grunt.file.readJSON("package.json"),
        shell: {
            libs: {
                command: "haxelib install haxeparser && " +
					"haxelib install hxparse && " +
					"haxelib install hxargs && " +
					"haxelib install compiletime && " +
					"haxelib install mcover && " +
					"haxelib install munit && " +
					"haxelib install tokentree && " +
					"haxelib install json2object "
            }
        },
        haxe: haxeOptions(),
        zip: {
            release: {
                src: [
					"src/**",
					"run.n", "run.js",
					"resources/default-hxformat.json",
					"resources/formatter-schema.json",
                    "haxelib.json", "README.md", "CHANGELOG.md", "LICENSE.md"
                ],
                dest: "formatter.zip",
                compression: "DEFLATE"
            }
        }
    });
    grunt.loadNpmTasks("grunt-haxe");
    grunt.loadNpmTasks("grunt-zip");
    grunt.loadNpmTasks("grunt-shell");
    grunt.registerTask("default", ["shell", "haxe:build", "haxe:test"]);
}

function haxeOptions() {
    return {
        build: {
            hxml: "buildAll.hxml"
		},
		test: {
			hxml: "buildTest.hxml"
		}
    };
}
