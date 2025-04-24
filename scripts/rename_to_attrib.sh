#!/usr/bin/env bash
set -e

if [ -z "$1" ]
then
	echo 'need some paths'
	exit 1
fi

# stackoverflow.com/a/296135731995812
quoteRe() {
	sed -e 's/[^^]/[&]/g; s/\^/\\^/g; $!a\'$'\n''\\n' <<<"$1" | tr -d '\n'
}

total=$(echo "$1" | wc -l)

echo "$1" | while read -r src; do
	filename="$(basename "$src")"

	if [ -z "$filename" ]
	then
		continue
	fi

	((i++)) || true
	src_dir="$(dirname "$src")"
	src_ext="${src##*.}"
	printf '%4d/%d: %s... ' "$i" "$total" "$filename"

	dirReadmePath="$(dirname "$src")/README.MD"
	dirAttribPath="$(dirname "$src")/attrib.md"
	if [ -f "$dirAttribPath" ]
	then
		attrib="$(grep -iPo "(?<=$(quoteRe "$filename")\s).+$" "$dirAttribPath")" || true
	fi

	# echo "dirAttribPath: $dirAttribPath"
	# echo "attrib: $attrib"

	if [ -z "$attrib" ]
	then
		echo "no attrib"
		continue
	fi

	newname="$(echo "${attrib,,}" | sed 's/([^)]*)//g' | sed 's/[][]//g' | inline-detox).${src_ext,,}"

	mainReadmePath="$(git rev-parse --show-toplevel)/README.MD"
	thumb_dir="$(git rev-parse --show-toplevel)/.internals/thumbnails"
	thumbnail_old="$(find "$thumb_dir" -type f -name "$filename" | head -n 1)"
	thumbnail_new="$(dirname "$thumbnail_old")/${newname}"
	src_new="${src_dir}/${newname}"
	filename_escaped="${filename// /%20}"

	if [ "$filename" = "$newname" ]
	then
		echo "skipped!"
		continue
	fi

	# echo
	# echo "thumbnail_old: $thumbnail_old"
	# echo "thumbnail_new: $thumbnail_new"

	git mv "$thumbnail_old" "$thumbnail_new"
	git mv "$src" "$src_new"
	sed -i "s/$(quoteRe "$filename")/$newname/g" "$dirAttribPath"
	sed -i "s/$(quoteRe "$filename_escaped")/$newname/g" "$dirReadmePath"
	sed -i "s/$(quoteRe "$filename_escaped")/$newname/g" "$mainReadmePath"

	echo "updated!"


done

