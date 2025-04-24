#!/usr/bin/env bash

indir="$1"
outpath="$2"

if [[ ! -d "$indir" ]]
then
	echo "need image input directory"
	exit 1
fi

if [[ -z "$outpath" ]]
then
	outpath="$PWD/$(basename "$indir")_polaroid.png"
fi

# TODO ask if the user wants to swap to the thumbnail version
# then find gitroot and swap it for gitroot/.internals/thumbdir
# TODO do the math to turn geo into a percent
# otherwise it's dependent on the -thumbnail arg and/or input size
# same for tile... somehow

echo "generating main image..."
montage -size 1000x1000 "${indir}/*.{jpg,jpeg,png,webp,gif}" \
	-auto-orient  -thumbnail "500x500>^" \
	-bordercolor Lavender -background black +polaroid \
	-gravity center -background none \
	-background none \
	-geometry -20+2  -tile x3 \
	"$outpath"

echo "downsizing image..."
convert "$outpath" -resize "3840x2160>^" "$outpath"

echo "$outpath"
