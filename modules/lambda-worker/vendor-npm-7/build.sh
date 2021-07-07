#!/usr/bin/env bash

set -e

rm -rf vendor-npm.zip nodejs/node_modules

cd nodejs
npm ci

cd ..
zip -9ry ./vendor-npm.zip nodejs -x 'nodejs/package*'
