#!/bin/bash

sed -e 's/https:\/\/beta.blog.3mdeb.com/https:\/\/blog.3mdeb.com/g' -i ../blog/config.toml
sed -e 's/https:\/\/beta.3mdeb.com/https:\/\/3mdeb.com/g' -i ../blog/themes/3mdeb/layouts/partials/header.html
