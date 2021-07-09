#!/usr/bin/env bash

# redirect stdout to descriptor 3
exec 3>&1
# redirect all stdout to stderr for logging
exec 1>&2

set -ex

mkdir -p $BUILD_PATH
unzip $BUILD_SOURCE_PATH -d $BUILD_PATH

cd $BUILD_PATH

eval $BUILD_COMMAND

cd $BUILD_TARGET_DIR
zip -9ry $BUILD_TARGET_PATH $BUILD_TARGET_FILES $BUILD_TARGET_EXCLUDE

# output json to stdout for reading in the js handler
echo '{"packagePath": "'$BUILD_TARGET_PATH'"}' >&3
