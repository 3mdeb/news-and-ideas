#!/bin/bash

rm -rf blog/public
docker run --rm -it -v $PWD/blog:/src -u hugo jguyomard/hugo-builder:0.54 hugo
