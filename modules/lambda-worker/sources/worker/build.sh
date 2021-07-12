#!/usr/bin/env bash

# redirect stdout to descriptor 3
exec 3>&1
# redirect all stdout to stderr for logging
exec 1>&2

set -ex

mkdir -p $BUILD_PATH $HOME
unzip $BUILD_SOURCE_PATH -d $BUILD_PATH
rm $BUILD_SOURCE_PATH

cd $BUILD_PATH
du -sh /tmp
df -h .

eval $BUILD_COMMAND

cd $BUILD_TARGET_DIR
zip -9Dmry $BUILD_TARGET_PATH $BUILD_TARGET_FILES $BUILD_TARGET_EXCLUDE

rm -rf $BUILD_PATH

# output json to stdout for reading in the js handler
echo '{"packagePath": "'$BUILD_TARGET_PATH'"}' >&3
