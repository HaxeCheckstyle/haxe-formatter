#!/bin/bash

mkdir -p bin

npx uglify-js-es6 run.js -o bin/formatter.uglify.js

echo '#!/usr/bin/env node' > bin/formatter.js
echo "" >> bin/formatter.js
cat bin/formatter.uglify.js >> bin/formatter.js
chmod 755 bin/formatter.js

rm bin/formatter.uglify.js
