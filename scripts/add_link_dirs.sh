#!/usr/bin/env bash

# TODO this functionality should probably be incorporated into make_gallery.sh

set -e

if [[ "$1" == "--test" ]]
then
  optTest=1
else
  optTest=0
fi

gitRoot="$(git rev-parse --show-toplevel)"
thisScriptDir="$(dirname -- "$0")"

find-videos() {
"$thisScriptDir/find-videos" "$@"
}

exclusions=( -not -ipath '*/gallery_maker' -not -ipath '*/gallery_maker/*' -not \( -type l -and -ipath '*/all/*' \) -not -path '*/thumbnails*' -not -path '*/.*' -not -path '*/temp *')

makeLinks(){
  arg="$1"

  linkyDirName="$(echo "$arg" | perl -pe 's/^\-+//g')"
  linkyDir="$gitRoot/$linkyDirName"

  echo "linkyDir: $linkyDir"
  echo "optTest: $optTest"

  # deleting before finding prevents some yikes recursion problems
  if [[ "$linkyDir" -ef "$gitRoot" ]]
  then
    echo "you almost deleted the root dir, you nincompoop! fix your config!"
    exit 1
  elif [[ "$optTest" == 0 ]]
  then
    rm -rf "$linkyDir"
  fi

  if [[ "$arg" == "--pdf" ]]
  then
    files="$(find "$gitRoot" -type f -iname '*.pdf' "${exclusions[@]}" | sort)"
  elif [[ "$arg" == '--video' ]]
  then
    files="$(find-videos "$gitRoot" "${exclusions[@]}" | sort)"
  else
    echo "bad arg"
    exit 1
  fi

  while read -r file
  do
    if [[ -z "$file" ]]
    then
      continue
    fi

    fileName="$(basename "$file")"
    dir="$(dirname "$file")"
    rootlessDir="${dir#"$gitRoot"/}"
    rootlessFile="${file#"$gitRoot"/}"
    destDir="$linkyDir/$rootlessDir"
    destPath="$destDir/$fileName"

    if [[ "$lastDir" != "$dir" ]]
    then
      echo "$rootlessDir"
    fi

    if [[ "$optTest" == 0 ]]
    then
      mkdir -p "$destDir"

      # ln -s "$file" "$destPath"
      echo "$rootlessFile" > "${destPath}.link"
    fi

    lastDir="$dir"

  done < <( echo "$files" )
}

makeLinks --pdf
makeLinks --video

