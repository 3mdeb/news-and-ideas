#!/bin/bash

docker run --rm -it -v $PWD/blog:/src -p 1313:1313 -u hugo jguyomard/hugo-builder:0.54 hugo server -w --bind=0.0.0.0
