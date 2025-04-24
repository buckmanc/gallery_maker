#!/usr/bin/env bash

gitRoot="$(git rev-parse --show-toplevel)"

# TODO are you sure?

find "$gitRoot" -type f -iname '*readme.md' -delete
find "$gitRoot" -type f -iname '*readme.html' -delete

