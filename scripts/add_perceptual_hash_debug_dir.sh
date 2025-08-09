#!/usr/bin/env bash

set -e

gitRoot="$(git rev-parse --show-toplevel)"
thisScriptDir="$(dirname -- "$0")"
phashDir="$gitRoot/debug/perceptual hash"

find-images() {
	"$thisScriptDir/find-images" "$@"
}

if (! type pyphash >/dev/null 2>&1 )
then
  echo "pyphash not found"
  exit 1
fi

dirs="$(find "$gitRoot" -mindepth 1 -type d -links 2 -not -ipath '*/.internals/*' -not -ipath '*/.git/*' -not -ipath '*/gallery_maker/*' | sort)"

rm -rf "$phashDir"

while read -r dir
do
  if [[ -z "$dir" ]]
  then
    continue
  fi

  rootlessDir="${dir#"$gitRoot"/}"

  echo -n "${rootlessDir}: "

  files="$(find-images "$dir")"
  hashes=''
  destDir="$phashDir/$rootlessDir"

  while read -r file
  do
    if [[ -z "$file" ]]
    then
      continue
    fi

    hashes+="$(pyphash "$file" 2> /dev/null || true)|$file"$'\n'
  done < <(echo "$files")

  hashesOnly="$(echo "$hashes" | cut -d '|' -f1)"
  dupeHashes="$(echo "$hashesOnly" | sort | uniq -d)"

  if [[ -z "$dupeHashes" ]]
  then
    dupeHashCount=0
  else
    dupeHashCount="$(echo "$dupeHashes" | wc -l)"
  fi

  echo -n "$dupeHashCount"

  while read -r dupeHash
  do
    if [[ -z "$dupeHash" ]]
    then
      continue
    fi

    matchingFiles="$(echo "$hashes" | grep -P "^$dupeHash" | cut -d '|' -f2)"

    hashDir="$destDir/$dupeHash"
    mkdir -p "$hashDir"

    while read -r matchingFile
    do
      if [[ -z "$matchingFile" ]]
      then
        continue
      fi

      fileName="$(basename "$matchingFile")"
      outPath="$hashDir/$fileName"

      ln -s "$matchingFile" "$outPath"

    done < <(echo "$matchingFiles")

  done < <(echo "$dupeHashes")

  echo

done < <(echo "$dirs")
