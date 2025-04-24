#!/usr/bin/env bash


gitRoot="$(git rev-parse --show-toplevel)"
"$gitRoot/scripts/find-images-or-videos" "$gitRoot" -not -ipath '*/.*' -size +100M | xargs --no-run-if-empty -d '\n' git-lfs track --filename
