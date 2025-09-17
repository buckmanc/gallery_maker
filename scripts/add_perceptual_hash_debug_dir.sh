#!/usr/bin/env bash

set -e

optAll=0
optFaceless=0
optFaces=0
optStrict=0
hashSize=8

if (! type pyphash >/dev/null 2>&1 )
then
  echo "pyphash not found"
  exit 1
fi

for arg in "$@"
do

  arg="${arg#--}"
  arg="${arg,,}"

  if [[ "$arg" == "all" ]]
  then
    optAll=1
    runType="$arg"
  elif [[ "$arg" == "faceless" ]]
  then
    optFaceless=1
    runType="$arg"
    if [[ "$optStrict" == 0 ]]
    then
      hashSize=4
    fi
  elif [[ "$arg" == "face" || "$arg" == "faces" ]]
  then
    optFaces=1
    runType="$arg"
  elif [[ "$arg" == "strict" ]]
  then
    optStrict=1
    hashSize=50
  fi

done

if [[ -z "$runType" ]]
then
  echo "need to specify --all, --faceless, or --faces"
  exit 1
elif (! type facedetect >/dev/null 2>&1 ) && [[ "$optAll" == 0 ]]
then
  echo "facedetect not found"
  echo "this script will only work in --all mode"
  exit 1
fi

if [[ "$optStrict" == 1 ]]
then
  runType="${runType}_strict"
fi

gitRoot="$(git rev-parse --show-toplevel)"
thisScriptDir="$(dirname -- "$0")"
phashDir="$gitRoot/debug/perceptual hash/$runType"

find-images() {
  "$thisScriptDir/find-images" "$@"
}

dirs="$(find "$gitRoot" -mindepth 1 -type d -links 2 -not -ipath '*/.internals/*' -not -ipath '*/.git/*' -not -ipath '*/gallery_maker/*' -not -ipath '*/debug/*' | sort)"

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
    elif [[ "$optFaceless" == 1 ]] && facedetect -q "$file" 2> /dev/null
    then
      continue
    elif [[ "$optFaces" == 1 ]] && ! facedetect -q "$file" 2> /dev/null
    then
      continue
    fi

    hashes+="$(pyphash --hash-size "$hashSize" "$file" 2> /dev/null || true)|$file"$'\n'
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

    hashDir="$destDir/${dupeHash:0:8}"
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
