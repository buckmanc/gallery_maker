#!/usr/bin/env bash

gitRoot="$(git rev-parse --show-toplevel)"

imgFiles=$("$gitRoot/scripts/find-images" . -type f -size +100M)
total=$(echo "$imgFiles" | wc -l)

if [[ -z "$imgFiles" ]]
then
	echo "no giant files found"
	exit 0
fi

echo "Reducing $total giant files to 8k..."

echo "$imgFiles" | while read src
do
	echo "Reducing $(basename "$src")..."
	convert -resize 7680x4320\>^ -strip "$src" "$src"
done

imgFiles=$("$gitRoot/scripts/find-images" . -type f -size +100M)
total=$(echo "$imgFiles" | wc -l)

if [[ -z "$imgFiles" ]]
then
	exit 0
fi

echo
echo "Reducing $total giant files to 4k..."
echo "$imgFiles" | while read src
do
	echo "Reducing $(basename "$src" | cut -c-$COLUMNS)..."
	convert -resize 3840x2160\>^ -strip "$src" "$src"
done

imgFiles=$("$gitRoot/scripts/find-images" . -type f -size +100M)
total=$(echo "$imgFiles" | wc -l)

if [[ -z "$imgFiles" ]]
then
	echo "no giant files remain"
else
	echo "$total giant files remain"
	echo "$imgFiles"
fi
