#!/usr/bin/env bash

set -e

gitRoot="$(git rev-parse --show-toplevel)"
thisScriptDir="$(dirname -- "$0")"

bannerDir="$gitRoot/.internals/banners"
tempImgPaths='/tmp/wallpaper-banner-temp.txt'
targetWidth=3000

mkdir -p "$bannerDir"

rootDirs="$(find "$gitRoot/.internals/thumbnails" -mindepth 1 -maxdepth 1 -type d | sort)"

# TODO if there are too few dirs with images to make the required number of banners, reuse dirs
# watch out for there being no working dirs tho
# probably switch to looping thru seq 1 5 and indexing rootDirs instead

iDir=0
echo "$rootDirs" | while read -r rootDir
do
  if [[ -z "$rootDir" ]]
  then
    continue
  fi

  iDir=$((iDir+1))
  rootDirName="$(basename "$rootDir")"
  outpath="$bannerDir/banner$iDir.png"

  if [[ -f "$tempImgPaths" ]]
  then
    rm "$tempImgPaths"
  fi

  # skip if exists
  # in other words, delete the banner to reshuffle it
  if [[ -f "$outpath" ]]
  then
    continue
  fi

  echo "making $rootDirName banner image..."

  # do a rough calc to get the right amount of images
  exampleImg="$("$thisScriptDir/find-images" "$rootDir" | head -n 1)"
  imgWidth="$(identify -format '%w' "$exampleImg"[0])"
  imgLimit="$(echo "($targetWidth / ($imgWidth+25)) -2" | bc -l | cut -d '.' -f1)"

  # should not occur, but just in case
  if [[ "$imgLimit" -le 0 ]]
  then
    imgLimit=10
  fi

  dirs="$(find "$rootDir" -mindepth 1 -type d | shuf)"
  dirCount="$(echo "$dirs" | wc -l)"
  i=0
  imgPerDir=1
  if [[ "$dirCount" -lt "$imgLimit" ]]
  then
    # chop off the decimal because rounding in bash is insane
    imgPerDir="$(echo "$imgLimit / $dirCount" | bc -l | cut -d '.' -f1)"
    imgPerDir=$((imgPerDir+1))
  fi

  # echo "rootDir: $rootDir"
  # echo "exampleImg: $exampleImg"
  # echo "targetWidth: $targetWidth"
  # echo "imgWidth: $imgWidth"
  # echo "imgLimit: $imgLimit"
  # echo "imgPerDir: $imgPerDir"

  while read -r dir
  do
    ((i++)) || true

    # echo "dir: $dir"

    if [[ -z "$dir" ]]
    then
      continue
    elif [[ "$i" -gt "$imgLimit" ]]
    then
      break
    fi

    imgPaths="$("$thisScriptDir/find-images" "$dir" -maxdepth 1 | shuf -n "$imgPerDir" | xargs -d '\n' -I{} echo '"'"{}[0]"'"')"
    if [[ -n "$imgPaths" ]]
    then
      echo "$imgPaths" >> "$tempImgPaths"
    fi
  done < <( echo "$dirs" )

  if [[ -f "$tempImgPaths" ]]
  then

    # not clear on all parts of this
    cat "$tempImgPaths" | shuf -n "$imgLimit" | montage -size 50x1 null: @- null: \
	    -auto-orient  -thumbnail "500x500>^" \
	    -bordercolor Lavender -background black +polaroid \
	    -gravity center -background none \
	    -background none \
	    -geometry -20+2  -tile x1 \
	    "$outpath"

    convert "$outpath" -resize "x500>^" "$outpath"

    rm "$tempImgPaths"
  # else
  #   echo "failed"
  fi

done
