#!/usr/bin/env bash

dir="$1"

if [[ -z "$dir" ]]
then
  dir="."
fi

files="$(find "$dir" -type f)"

while read -r path
do
  pathDate="$(echo "$path" | grep -iPo '\d{4}-\d{2}(-\d{2}| )' | tail -n 1)"
  if [[ -z "$pathDate" ]]
  then
    pathDate="nopers"
  fi

  filename="$(basename "$path")"

  exifDate="$(file "$path" | grep -iPo '(?<=datetime=)[^ ]+' | perl -pe 's/:/-/g')"

  if [[ -z "$exifDate" || "$pathDate" == "$exifDate" ]]
  then
    continue
  fi

  echo -e "$pathDate\t$filename\t$exifDate" | column -t
done < <( echo "$files" )

