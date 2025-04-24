#!/usr/bin/env bash

# a simple script for updating derivative repos without worrying about the hefty images

repo="buckmanc/wallpapers"
urlRoot="https://api.github.com/repos/$repo/contents/"
gitRoot=$(git rev-parse --show-toplevel)

if [[ -z "$gitRoot" ]]
then
	gitRoot="."
	parentDir="$(basename "$PWD")"
	if [[ "$parentDir" == "scripts" ]]
	then
		gitRoot+="/.."
	fi
fi

set -e

nabFile()
{
	path="$1"
	json="$(curl -L "$urlRoot/$path")"
	if [[ "$json" == "["*"]" ]]
	then
		isDir=1
	else
		isDir=0
	fi

	if [[ "$isDir" == 0 ]]
	then
		outDir="$(dirname "$path")"
		if [[ "$outDir" != "." && ! -d "$outDir" ]]
		then
			mkdir "$outDir"
		fi

		curl -H 'Accept: application/vnd.github.v3.raw' -OL --output-dir "$outDir" "$urlRoot/$path"
	else
		paths="$(echo "$json" | jq -rc ".[].path")"
		while read -r path
		do
			if [[ -z "$path" ]]
			then
				continue
			fi

			nabFile "$path"
		done < <( echo "$paths" )
	fi
}

nabFile "make_gallery.sh"
nabFile "update.sh"
nabFile "scripts"

# TODO check downloaded files for "api rate limit exceeded"

