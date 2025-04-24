#!/usr/bin/env bash

set -e

gitRoot=$(git rev-parse --show-toplevel)
modTimeScriptPath="$gitRoot/scripts/update_mod_time.sh"

git fetch --depth 1
if [[ $(git rev-parse HEAD) == $(git rev-parse @{u}) ]]
then
	echo "already up to date"
else
	# smooth out unattended updates
	rm -f "$gitRoot/.git/index.lock"
	git checkout .
	git clean -f .
	git reset --hard origin/main
	git clean -dfx
	git gc --prune=all

	# attempt to set execute perms on the mod time script
	if [[ -f "$modTimeScriptPath" && ! -x "$modTimeScriptPath" ]]
	then
		chmod +x "$modTimeScriptPath" || true
	fi

	if [[ -x "$modTimeScriptPath" ]]
	then
		"$modTimeScriptPath"
	elif [[ -f "$modTimeScriptPath" ]]
	then
		# if the mod time update script exists but doesn't have execute perms
		# then try to run it the termux way
		eval "$(cat "$modTimeScriptPath")"
	fi
fi
