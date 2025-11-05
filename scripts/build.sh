#!/bin/bash

echo "Building from branch: ${GITHUB_REF}"

HUGO_FLAGS=""

if [ "${GITHUB_REF}" = "refs/heads/master" ]; then
  echo "On master branch - setting URLs to production..."
  sed -e 's/https:\/\/beta.blog.3mdeb.com/https:\/\/blog.3mdeb.com/g' -i ../blog/config.toml
  sed -e 's/https:\/\/beta.3mdeb.com/https:\/\/3mdeb.com/g' -i ../blog/themes/3mdeb/layouts/partials/header.html

  echo "Changes:"
  git diff
elif [ "${GITHUB_REF}" = "refs/heads/develop" ]; then
  echo "On develop branch - building with future posts..."
  HUGO_FLAGS="--buildFuture"
fi

cd ../blog
./hugo ${HUGO_FLAGS}
