#!/usr/bin/env bash

if [[ -z "$1" || ! -f "$1" ]]
then
	echo "need source image path"
	exit 1
fi

for inPath in "$@"
do
	outPath="${inPath%.*}_enlarged.${inPath##*.}"
	convert "$inPath" -interpolate integer -filter point -resize "4000x4000^<" "$outPath"
done
