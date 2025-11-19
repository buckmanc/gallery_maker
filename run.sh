#!/usr/bin/env bash

# convenience script

gitRoot="$(git rev-parse --show-toplevel)"
repoName="$(basename "$gitRoot")"
repoName="${repoName,,}"
galleryMakerDefaultPath="$gitRoot/gallery_maker"
makeGalleryPaths=("$gitRoot/gallery_maker/make_gallery.sh" "$gitRoot/make_gallery.sh")

for path in "${makeGalleryPaths[@]}"
do
	if [[ -x "$path" ]]
	then
		makeGalleryPath="$path"
		break
	fi
done

if [[ -z "$makeGalleryPath" ]]
then
	echo "could not find make_gallery.sh"
	exit 1
fi

txt(){
	if [[ -x "$HOME/bin/txtme" ]]
	then
		"$HOME/bin/txtme" "$@"
	fi
	echo "$@"
}

if [[ -d "$galleryMakerDefaultPath" ]]
then
	echo "updating gallery maker:"
	git -C "$galleryMakerDefaultPath" pull
fi

if ! "$makeGalleryPath"
then
	txt "$repoName update failed"
else
	txt "$repoName updated"
fi

# induce git to refresh the index if needed
git status > /dev/null
