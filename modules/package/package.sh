#!/usr/bin/env bash

# redirect stdout to descriptor 3
exec 3>&1
# redirect all stdout to stderr for logging
exec 1>&2

set -ex

output=$1

platform=$(uname -s | tr '[:upper:]' '[:lower:]')
cpu=$(uname -m)
zip=$(dirname "$0")/vendor/zip-$platform-$cpu

# ensure consistent timestamps of sources
find . -exec touch -t 204901010000 {} +

mkdir -p $(dirname $output)
$zip -9ry "$@"

echo '{"outputFile": "'$output'"}' >&3
