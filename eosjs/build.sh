#!/usr/bin/env bash

npm install
npm run build
tsc -p ./tsconfig.json && cp src/ripemd.es5.js dist/ripemd.js
