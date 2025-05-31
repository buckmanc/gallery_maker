#!/usr/bin/env bash


gitRoot="$(git rev-parse --show-toplevel)"
thisScriptDir="$(dirname -- "$0")"
"$thisScriptDir/find-images-or-videos" "$gitRoot" -not -ipath '*/.*' -size +100M -print0 | xargs --no-run-if-empty -0 git-lfs track --filename
