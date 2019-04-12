#!/bin/bash

if [ "${TRAVIS_BRANCH}" = "master" ]; then
  echo "On master branch - setting URLs to production..."
  sed -e 's/https:\/\/beta.blog.3mdeb.com/https:\/\/blog.3mdeb.com/g' -i ../blog/config.toml
  sed -e 's/https:\/\/beta.3mdeb.com/https:\/\/3mdeb.com/g' -i ../blog/themes/3mdeb/layouts/partials/header.html
fi

cd ../blog
./hugo
