#!/bin/bash

echo "Building from branch: ${TRAVIS_BRANCH}"

if [ "${TRAVIS_BRANCH}" = "fix_production_url" ]; then
  echo "On master branch - setting URLs to production..."
  sed -e 's/https:\/\/beta.blog.3mdeb.com/https:\/\/blog.3mdeb.com/g' -i ../blog/config.toml
  sed -e 's/https:\/\/beta.3mdeb.com/https:\/\/3mdeb.com/g' -i ../blog/themes/3mdeb/layouts/partials/header.html

  echo "Changes:"
  git diff
fi

cd ../blog
./hugo
