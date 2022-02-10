#!/bin/bash

docker run --rm -it -v $PWD/blog:/src -p 1313:1313 -u $(id -u) klakegg/hugo:0.92.1 server
