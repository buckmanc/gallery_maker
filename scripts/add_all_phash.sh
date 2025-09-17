#!/usr/bin/env bash

set -e

# gitRoot="$(git rev-parse --show-toplevel)"
thisScriptDir="$(dirname -- "$0")"
mainScriptPath="$thisScriptDir/add_perceptual_hash_debug_dir.sh"

# "$mainScriptPath" --all
# face detection is not reliable enough for this to be useful
# "$mainScriptPath" --faceless
"$mainScriptPath" --all --strict
