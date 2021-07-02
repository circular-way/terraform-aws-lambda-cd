#!/bin/bash -e

## Run this with: docker run --rm -v "$PWD":/tmp amazonlinux /tmp/build.sh

yum install unzip zip -y

cd /opt
mkdir -p bin lib
cp /bin/unzip /bin/zip ./bin
cp /usr/lib64/libbz2.so.1 ./lib

zip -r /tmp/vendor.zip ./*
