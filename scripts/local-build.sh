#!/bin/bash

rm -rf blog/public
docker run --rm -it -v $PWD/blog:/src -u $(id -u) klakegg/hugo:0.92.1
