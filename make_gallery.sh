#!/usr/bin/env bash

set -e

# heavily modified from github.com/jonascarpay/Wallpapers

# TODO check dependencies


# stackoverflow.com/a/296135731995812
quoteRe() {
	sed -e 's/[^^]/[&]/g; s/\^/\\^/g; $!a\'$'\n''\\n' <<<"$1" | tr -d '\n'
}

if [[ -n "$1" ]]
then
	gitRoot="$1"
	if [[ ! -d "$gitRoot" ]]
	then
		echo "$gitRoot does not exist"
		exit 1
	fi
else
	gitRoot="$(git rev-parse --show-toplevel)"
fi

thisScriptDir="$(dirname -- "$0")"
branchName="$(git branch --show-current)"
shortRemoteName="$(git remote -v | grep -iP '(github|origin)' | grep -iPo '[^/:]+/[^/]+(?= )' | perl -pe 's/\.git$//g' | head -n1)"
raw_root="https://raw.githubusercontent.com/$shortRemoteName/main"
repoUrl="https://github.com/$shortRemoteName"
repoName="${shortRemoteName#*/}"
repoNameCap="$(echo "$repoName" | perl -p -e 's/[_\-]/ /g;' -e 's/\b(.)/\u\1/g;')"

# echo "shortRemoteName: $shortRemoteName"

tocMD="${gitRoot}/.internals/tableofcontents.md"
cssPathBigImages="/.internals/bigimages.css"
cssPathTinyImages="/.internals/tinyimages.css"
thumbnails_dir="$gitRoot/.internals/thumbnails"
thumbnails_old_dir="$gitRoot/.internals/thumbnails_old"
readmeTemplatePath="$gitRoot/.internals/README_template.md"
readmeTemplateDefaultPath="$thisScriptDir/.internals/README_template_default.md"
fileListDir="$gitRoot/.internals/filelist"
fileListFile="$fileListDir/${branchName}.log"
fileListFileMain="$fileListDir/main.log"
cacheDir="$HOME/.cache/gallery_maker"
tempDir="/tmp/gallery_maker"

headerDirNameRegex='s/^(\d{2}|[zZ][xyzXYZ])[ \-_]{1,3}//g'
subDirIdRegex='s/[ \-_"#]+/-/g'

githubFileMaxBytes=98000000
githubPushMaxBytes=1980000000
githubLfszMaxBytes=1980000000

rm -f "$tocMD"

update-script() {

	filename="$1"
	homePath="$HOME/bin/$filename"
	scriptsPath="$thisScriptDir/scripts/$filename"
	if [[ -f "$homePath" && "$gitRoot" == "$thisScriptDir" ]]
	then
		cp "$homePath" "$scriptsPath"
	fi
}

mkdir -p "$gitRoot/.internals"

# pull over internals from the gallery project
while read -r path
do
	cp "$path" "$gitRoot/.internals/" --update=none
done < <( find "$thisScriptDir/.internals" -maxdepth 1 -mindepth 1 -type f -not -iname 'update_mod_time.sh' -not -iname 'readme_template_default.md')

update-script "find-images"
update-script "find-videos"
update-script "find-images-or-videos"
update-script "wallpaper-magick"

if [[ "$gitRoot" -ef "$thisScriptDir" ]]
then
	excludeGalleryMaker=( )
else
	excludeGalleryMaker=( -not -ipath '*/gallery_maker' -not -ipath '*/gallery_maker/*' )
fi

find-images-including-thumbnails() {
	imgAndVids="$("$thisScriptDir/scripts/find-images-or-videos" "$@"	-not -path '*/scripts/*' -not -path '*/repo_scripts/*' -not -type l -not -path '*/temp *' "${excludeGalleryMaker[@]}")"
	links="$(find "$@" -iname '*.link'									-not -path '*/scripts/*' -not -path '*/repo_scripts/*' -not -type l -not -path '*/temp *' "${excludeGalleryMaker[@]}")"

	# deliberately sorting links to the bottom here
	# for the sake of link thumbnails depending on the source thumbnail
	if [[ -n "$imgAndVids" && -n "$links" ]]
	then
		echo -n "$imgAndVids"$'\n'"$links"
	else
		echo -n "$imgAndVids""$links"
	fi
}
find-images() {
	find-images-including-thumbnails "$@" -not -path '*/thumbnails*' -not -path '*/.*'
}
find-images-main() {
	find-images "$gitRoot" -mindepth 2 "${excludeGalleryMaker[@]}"
}
find-mod-time() {
	find "$1" -type f -printf "%T+\n" | sort -nr | head -n 1
}
wallpaper-magick(){
	"$thisScriptDir/scripts/wallpaper-magick" "$@"
}
bottom-level-dir(){
	if [[ "$(find-images "$1" -maxdepth 1 | wc -l)" -gt 0 ]]
	then
		echo 1
	else
		echo 0
	fi
}

getModEpoch() {

	duPath="$1"

	if [[ -e "$duPath" ]]
	then
		modEpoch="$(du "$duPath" --time --max-depth 0 --time-style=+%s | cut -f2 || echo 0)"
	else
		modEpoch=0
	fi

	echo "$modEpoch"
}

getThumbnailPath() {
	path="$1"
	optOld=0
	optLink=0
	if [[ "$2" == "--old" ]]
	then
		optOld=1
	fi

	targetBase="$path"

	# if this is a link file, remove ".link" and expect the extension for the linked file behind it
	if [[ "$targetBase" =~ \.link$ ]]
	then
		optLink=1
		targetBase="$(echo "$targetBase" | perl -pe 's/\.link$//g')"
	fi

	ext="${targetBase##*.}"
	ext="${ext,,}"
	targetBase="${targetBase%.*}"

	if [[ "$optLink" == 1 ]]
	then
		targetBase="${targetBase}_link"
	fi

	if [[ "$optOld" == 0 ]]
	then
		targetBase="${thumbnails_dir}/${targetBase#"$gitRoot/"}"
	else
		targetBase="${thumbnails_old_dir}/${targetBase#"$gitRoot/"}"
	fi

	newExt=''

	# if it's a known movie type, make a gif thumbnail
	if [[ "$ext" =~ ^(3gp|3g2|avi|mp4|m4v|mpg|mov|wmv|webm|mkv|vob) ]]
	then
		newExt="gif"
	# otherwise, limit thumbnail types
	elif ! [[ "$ext" =~ ^(jpe?g|png|gif) ]]
	then
		newExt="png"
	else
		newExt="$ext"
	fi

	echo "${targetBase}.$newExt"
}

# store a list of all our files in lfs
# need to expand them to full paths to match what we'll get from gnu find
# TODO windows will use different formats for drive letters between git rev-parse --show-toplevel and find
lfsFiles="$(git -C "$gitRoot" lfs ls-files --name-only | xargs --no-run-if-empty -d '\n' realpath)"

fitDir="$gitRoot/.internals/wallpapers_to_fit"
if [[ -d "$fitDir" ]]
then
	imagesToFit="$(find-images "$fitDir")"
fi

i=0
totalImagesToFit=$(echo "$imagesToFit" | wc -l)

echo "--checking for missing images to fit..."
echo "$imagesToFit" | while read -r src; do
	((i++)) || true
	if [[ -z "$src" ]]
	then
		continue
	fi
	filename="$(basename -- "$src")"
	printf '\033[2K%4d/%d: %s...' "$i" "$totalImagesToFit" "$filename" | cut -c "-$COLUMNS" | tr -d $'\n'

	target="${src/#"$fitDir"/"$gitRoot"}"

	# # temp fix: if jpeg target exists, burn it
	# if [[ -f "$target" ]] && echo "$target" | grep -Piq "\.jpe?g$"
	# then
	# 	rm "$target"
	# fi
	# swap jpegs to pngs to avoid a greyscaling bug

	target="$(echo "$target" | perl -pe 's/\.(jpe?g|svg)$/.png/g')"
	thumbnailPath="$(getThumbnailPath "$target")"
	targetDir="$(dirname -- "$target")"
	srcExt="${src##*.}"
	srcExt="${srcExt,,}"

	if [[ -f "$target" ]]
	then
		echo -en '\r'
		continue
	fi

	if echo "$src" | grep -iq "$fitDir/desktop"
	then
		args="-m landscape"

		if [[ "$srcExt" == "svg" ]]
		then
			args+=" size '2000x' -background none"
		fi
	else
		args="-m portrait"
		if [[ "$srcExt" == "svg" ]]
		then
			args+=" size 'x2000' -background none"
		fi
	fi

	# if echo "$src" | grep -iq "album cover art"
	# then
	# 	args+=" -b"
	# fi

	# TODO handle svgs

	mkdir -p "$targetDir"
	wallpaper-magick -i "$src" -o "$target" $args > /dev/null

	if [[ ! -f "$target" ]]
	then
		echo "failed to create target image"
		exit 1
	fi

	if [[ -f "$thumbnailPath" ]]
	then
		rm "$thumbnailPath"
	fi

	echo ""
done

echo -e "\r"

# if perceptual hashing is available, append the hash to the start of the file for applicable categories
if type pyphash >/dev/null 2>&1
then
	echo -n "--checking for missing perceptual hash sort data..."
	imgFiles="$(find-images-main)"
	echo "$imgFiles" | while read -r path
	do
		filename="$(basename -- "$path")"
		ext="${filename##*.}"
		ext="${ext,,}"
		if [[ "$ext" == "link" ]]
		then
			continue
		fi

		shortPath="${path/#"$gitRoot"/}"
		# only use perceptual hash filenames for specific folders
		# only misc folders at one level deep
		if echo "$shortPath" | grep -qiP "(/forests/|/space/|/space - fictional/|^/?[^/]+/misc/|/leaves/|/cityscapes/)" && ! echo "$filename" | grep -qiP '^[a-f0-9]{16}_' && ! echo "$shortPath" | grep -qiP '(screenshots)'
		then
			echo -n "moving $shortPath..."
			newPath="$(dirname -- "$path")/$(pyphash "$path")_$filename"
			mv --backup=numbered "$path" "$newPath"
			echo "done"
		fi

	done

	echo "done!"
fi

echo -n "--checking for webp's / bmp's to convert..."
webpFiles="$(find "$gitRoot" -type f -iname '*.webp' -not -ipath '*/.internals/thumbnails/*' "${excludeGalleryMaker[@]}")"
echo "$webpFiles" | while read -r path
do
	if [[ -z "$path" ]]
	then
		continue
	fi

	target="$(echo "$path" | perl -pe 's/(\.(gif|jpe?g|png|bmp))?\.(webp|WEBP|bmp|BMP)$/.png/g')"
	echo -n "converting ${path/#"$gitRoot"/}..."
	convert "${path}[0]" "$target" && rm "$path"
	echo "done"
done

echo "done!"

echo -n "--checking for unhappy filenames..."
unhappyFiles="$(find-images-including-thumbnails "$gitRoot" -iregex '.*/[_-]+.*')"
echo "$unhappyFiles" | while read -r path
do
	if [[ -z "$path" ]]
	then
		continue
	fi

	dir="$(dirname -- "$path")"
	file="$(basename -- "$path")"
	outFile="$(echo "$file" | perl -pe 's/^[_-]+//g')"
	outPath="$dir/$outFile"

	if [[ "$path" -ef "$outPath" ]]
	then
		echo "conflict found with $outFile!"
	else
		echo -n "moving $outFile..."
		mv "$path" "$outPath"
		echo "done"
	fi
done

echo "done!"

# do weird branch specific stuff
if [[ "$branchName" != "main" ]]
then

	echo "todo"

fi

if [[ -d "$thumbnails_old_dir" ]]
then
	echo "--fixing interrupted run..."
	rsync -hau --remove-source-files --prune-empty-dirs "$thumbnails_old_dir/" "$thumbnails_dir"
	rm -r "$thumbnails_old_dir"
fi

echo "--updating thumbnails..."

mkdir -p "$thumbnails_dir"
mkdir -p "$fileListDir"
mv "$thumbnails_dir" "$thumbnails_old_dir"
mkdir -p "$thumbnails_dir"


imgFilesAll="$(find-images-main)"
# .link files are sorted last
# to assure that the destination thumbnail already exists

i=0
totalImages=$(echo -n "$imgFilesAll" | wc -l)

echo "$imgFilesAll" | while read -r src; do

	if [[ -z "$src" ]]
	then
		continue
	fi

	((i++)) || true
	filename="$(basename -- "$src")"
	printf '\033[2K%4d/%d: %s...' "$i" "$totalImages" "$filename" | cut -c "-$COLUMNS" | tr -d $'\n'

	target="$(getThumbnailPath "$src")"
	thumbnail_old="$(getThumbnailPath "$src" --old)"
	srcExt="${src##*.}"
	srcExt="${srcExt,,}"
	targetExt="${target##*.}"
	targetExt="${targetExt,,}"
	srcFileNameNoExt="$(basename "$src")"
	srcFileNameNoExt="${srcFileNameNoExt%%.*}"

	# use the base file as the source for links
	if [[ "$srcExt" == "link" ]]
	then
		thumbSource="${src%.link}"
	else
		thumbSource="$src"
	fi
	thumbSourceExt="${thumbSource##*.}"
	thumbSourceExt="${thumbSourceExt,,}"

	target_dir="$(dirname -- "$target")"
	mkdir -p "$target_dir"

	if [[ -f "$thumbnail_old" ]]; then
		mv "$thumbnail_old" "$target"
		echo -en "\r"

	# make a new, regular thumbnail
	else
		if [[ "$src" == *"/mobile/"* ]]; then
			targetWidth=97
			aspectRatio="9/20"
		else
			targetWidth=200
			aspectRatio="16/9"
		fi

		targetHeight=$(echo "$targetWidth/($aspectRatio)" | bc -l)
		targetHeight="${targetHeight%%.*}"
		targetDimensions="${targetWidth}x${targetHeight}"
		fileSize="$(stat -c %s "$src")"

		# echo
		# echo "aspectRatio: $aspectRatio"
		# echo "targetDimensions: $targetDimensions"

		fitCaret="^"
		bgColor="none"

		# altered logic for images that sit in the center
		if echo "$thumbSource" | grep -iq "/floaters/"
		then
			fitCaret=""
			bgColor="black"
		# altered logic for terminal images, which are 2/3 alpha and 1/3 black bg anyway
		elif echo "$thumbSource" | grep -iq "/terminal/"
		then
			bgColor="black"
		fi

		# TODO if fitting a portrait image into a landscape thumbnail
		# center the image on the line between 1/3 and 2/3

		timestamp=''
		# if it's a known movie type, make a temp chunk out of the middle
		# instead of doing a thumbnail from the beginning
		if [[ "$thumbSourceExt" =~ ^(3gp|3g2|avi|mp4|m4v|mpg|mov|wmv|webm|mkv|vob|gif) ]]
		then
			start=0
			fin=0
			ffJson="$(ffprobe -i "$thumbSource" -loglevel error -show_entries format=duration -show_entries stream=width,height -of json)"
			seconds="$(echo "$ffJson" | jq -r '.format.duration' | perl -pe 's/\..+?$//g')"
			ffWidth="$(echo "$ffJson" | jq -r '.streams[0].width')"
			ffHeight="$(echo "$ffJson" | jq -r '.streams[0].height')"

			timestamp="$(printf '%02d:%02d:%02d' $((seconds/3600)) $((seconds%3600/60)) $((seconds%60)))"

			# trim off hours if all zero
			# trim off leading zero in the tens place
			timestamp="$(echo "$timestamp" | perl -p -e 's/^00:(?=\d\d:\d\d)//g;' -e 's/^0(?=\d)//g;')"

			start=$((seconds/3))
			fin=$((start+2))

			# echo -n "start time: $start"

			if [[ "$start" -gt 0 ]]
			then
				mkdir -p "$tempDir"

				# if final output is going to be a gif, have ffmpeg make a gif
				# otherwise use the same format as the source
				if [[ "$targetExt" == "gif" ]]
				then
					ffmpegExt="gif"
				else
					ffmpegExt="$thumbSourceExt"
				fi

				ffmpegTemp="$tempDir/$srcFileNameNoExt.$ffmpegExt"
				rm -f "$ffmpegTemp"

				# resizing here is more performant
				# shrink the smallest dimension to match the corresponding thumbnail dimension
				# ...shrinking to 2x and letting image magick to do the rest later
				# for some reason if we shrink all the way down with ffmpeg the colors go wonky
				# don't know why

				if [[ "$ffWidth" == "null" || "$ffHeight" == "null" ]]
				then
					scaleRes="320:-2"
				elif [[ "$ffWidth" -gt "$ffHeight" ]]
				then
					scaleRes="$((targetWidth*2)):-2"
				else
					scaleRes="-2:$((targetHeight*2))"
				fi

				# use special gif args for optimal output
				if [[ "$ffmpegExt" == "gif" ]]
				then
					videoFilterArg="fps=10,scale=${scaleRes}:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
				else
					videoFilterArg="scale=${scaleRes}:flags=lanczos"
				fi

				# ffmpeg -y -nostdin -loglevel error -ss "$start" -to "$fin" -i "$thumbSource" -c:v copy -c:a copy "$ffmpegTemp" #|| true
				ffmpeg -y -nostdin -loglevel error -ss "$start" -to "$fin" -i "$thumbSource" -vf "$videoFilterArg" "$ffmpegTemp" || true

				if [[ -f "$ffmpegTemp" ]]
				then
					thumbSource="$ffmpegTemp"
				fi
			fi
		fi

		frames="0-30"

		# if the target is a known still image format, only use one frame
		# this prevents things like PDF pages splitting into multiple pngs
		if [[ "$targetExt" =~ (png|jpe?g) ]]
		then
			frames="0"
		fi

		# resize images, then crop to the desired resolution
		convert -background "$bgColor" -dispose none -auto-orient -thumbnail "${targetDimensions}${fitCaret}" -unsharp 0x1.0 -gravity Center -extent "$targetDimensions" -layers optimize +repage "$thumbSource"[$frames] "$target" || true

		# write a filler image on failure
		if [[ ! -f "$target" ]]
		then
			convert -background transparent -fill white -size "$targetDimensions" -gravity center -stroke black -strokewidth "2" caption:"?" "$target"
		fi

		# build the caption
		caption=''
		if echo "$lfsFiles" | grep -Piq "$src"
		then
			caption+="lfs"$'\n'
		elif [[ "$fileSize" -gt "$githubFileMaxBytes" ]]
		then
			caption+="X"$'\n'
		fi
		if [[ "$srcExt" == "pdf" ]]
		then
			caption+="$srcExt"$'\n'
		fi
		if [[ -n "$timestamp" && "$srcExt" != "link" ]]
		then
			caption+="$timestamp"$'\n'
		fi

		# slap the caption on the thumbnail if present
		if [[ -n "$caption" ]]
		then
			# trim off leading/trailing new lines
			caption="$(echo "$caption" | perl -0777pe 's/(\n+$|^\n+)//g;')";

			# caption
			# echo "captioning thumbnail with '$caption'"
			convert "$target" -pointsize 30 -coalesce null: -background transparent -fill white -gravity southeast -stroke black -strokewidth "1" -geometry "+4-2" -interline-spacing -10 caption:"$caption" -layers composite +repage "$target"
		fi

		if [[ "$srcExt" == "link" ]]
		then
			url="$(cat "$src")"
			domain="$(echo "$url" | grep -iPo '^https?://[^/]+')"
			faviconUrl="$domain/favicon.ico"
			faviconPath="$cacheDir/$(echo "$domain" | perl -p -e 's|[:/\.]||g;' -e 's/^(https?|www)+//g;').ico"

			if [[ ! -f "$faviconPath" ]]
			then
				mkdir -p "$cacheDir"
				curl -L "$faviconUrl" -o "$faviconPath"
			fi

			# slap the symbol on top of the thumbnail
			convert "$target" -coalesce null: \( "$faviconPath" -trim +repage \) -gravity southeast -geometry "+4+4" +dither -layers composite "$target"
		fi

		# clear temp file if present
		if [[ -f "$ffmpegTemp" ]]
		then
			rm "$ffmpegTemp"
		fi

		echo    "${src#"$gitRoot"}~$(date +%s)" >> "$fileListFile"

		echo ""
	fi
done

rm -rf "$thumbnails_old_dir"

if [[ -f "$fileListFile" ]]
then
	# sort the file list to contain only the most recent entry per file
	cat "$fileListFile" | sort -t~ -k1,2r | sort -t~ -k1,1 -u | sponge "$fileListFile"
fi

echo ""

echo "--updating readme md's..."

homeReadmePath="${gitRoot}/README.MD"
rootReadmePath="${gitRoot}/README_ALL.MD"

# min depth > 0 disables the generation of readme_all / rootReadmePath
directories="$(find "$gitRoot" -mindepth 1 -type d -not -path '*/.*' -not -path '*/scripts' -not -ipath '*/repo_scripts' -not -path '*/temp *' -not -path '*/thumbnails_test' "${excludeGalleryMaker[@]}")"
totalDirs="$(echo "$directories" | wc -l)"
i=0
iDir=0
iMdUnchanged=0
iMdSkip=0

while read -r dir; do

	if [[ -z "$dir" ]]
	then
		continue
	fi

	((iDir++)) || true
	printf -v dirStatus '\033[2K%3d/%d:' "$iDir" "$totalDirs"
	friendlyDirName="${dir/"$gitRoot"}"
	# thumbDir="$gitRoot/.internals/thumbnails/$friendlyDirName"

	dirReadmePath="$dir/README.MD"
	dirHtmlReadmePath="$dir/README.html"
	# don't overwrite the real root readme
	if [[ "$dirReadmePath" == "$homeReadmePath" ]]
	then
		dirReadmePath="$rootReadmePath"
	fi

	dirChangeEpoch="$(getModEpoch "$dir")"
	mdChangeEpoch="$(getModEpoch "$dirReadmePath")"
	htmlChangeEpoch="$(getModEpoch "$dirHtmlReadmePath")"

	if [[ "$mdChangeEpoch" -lt "$htmlChangeEpoch" ]]
	then
		mdChangeEpoch="$htmlChangeEpoch"
	fi

	# echo ""
	# echo "dirChangeEpoch:      $dirChangeEpoch"
	# echo "mdChangeEpoch:       $mdChangeEpoch"

	if [[ "$dirChangeEpoch" != 0 && "$mdChangeEpoch" != 0 && "$dirChangeEpoch" -le "$mdChangeEpoch" ]]
	then
		iMdSkip=$((iMdSkip+ 1))
		echo -en '\r'
		continue
	fi

	bottomLevelDir="$(bottom-level-dir "$dir")"

	# TODO custom sort imgFiles
	# use a sort key to handle dates
	#	like, for example, remove '(?<=\d)[\-_ ](?=\d)'
	imgFiles="$(find-images "$dir" | sort -t'/' -k1,1 -k2,2 -k3,3 -k4,4 -k5,5 -k6,6 -k7,7)"
	i=0
	totalDirImages=$(echo "$imgFiles" | wc -l)

	headerDirName="$(basename -- "$dir" | perl -pe "$headerDirNameRegex")"
	mdText=''
	mdText+="# $headerDirName - $(numfmt --grouping "$totalDirImages")"$'\n'

	# only find immediate sub dirs
	subDirs="$(find "$dir" -mindepth 1 -maxdepth 1 -type d | sort)"
	# subDirs="$(echo "$imgFiles" | sed -r 's|/[^/]+$||' | sort -u)"

	# if [[ "$newSubDirs" != "$subDirs" ]]
	# then
	# 	echo "newSubDirs:"
	# 	echo "$newSubDirs"
	# 	echo
	# 	echo "oldSubDirs:"
	# 	echo "$subDirs"
	# 	echo
	# 	exit 1
	# fi

	while read -r subDir; do
		subDirName="$(basename -- "$subDir" | perl -pe "$headerDirNameRegex")"

		if [[ -z "$subDirName" ]]
		then
			continue
		fi
		customHeaderID="$(echo "${subDirName}" | perl -pe "$subDirIdRegex")"
		imgFolderPathReggie="$(quoteRe "${subDir}/")"
		folderToc="- [$subDirName](#$customHeaderID) - $(echo "$imgFiles" | grep -iPc "$imgFolderPathReggie" | numfmt --grouping)"
		if [[ "$folderToc" != *" - 0" ]]
		then
			mdText+="$folderToc"$'\n'
		fi
	done < <( echo "$subDirs" )

	while read -r subDir; do

		imgFolderPathReggie="$(quoteRe "${subDir}/")"
		subDirImgFiles="$(echo "$imgFiles" | grep -iP "$imgFolderPathReggie" || true)"

		while read -r imgPath; do
			if [[ -z "$imgPath" ]]
			then
				continue
			fi

			((i++)) || true
			imgFilename="$(basename -- "$imgPath")"
			printf '%s%4d/%d: %s...' "$dirStatus" "$i" "$totalDirImages" "$friendlyDirName" | cut -c "-$COLUMNS" | tr -d $'\n'

			imgDir="$(dirname "$imgPath")"
			imgExt="${imgPath##*.}"
			imgExt="${imgExt,,}"

			attrib=''
			dirAttribPath="$imgDir/attrib.md"
			if [ -f "$dirAttribPath" ]
			then
				# not sorting attrib file to improve performance
				# if manually editing you'll just have to sort it yourself
				# or not
				attrib="$(grep -iPo "(?<=$(quoteRe "$imgFilename")\s).+$" "$dirAttribPath" | sed 's/ \+/ /g')" || true
			fi

			# attempted to pull attribution from metadata using imagemagick but did not succeed

			# allow for initial load of attribution from the filename
			if [[ -z "$attrib" ]] && echo "$imgFilename" | grep -qiP "[-_ ]by[-_ ]"
			then
				attrib="$(echo "${imgFilename%%.*}" | sed 's/[-_]/ /g' | sed 's/\( \|^\)\w/\U&/g' | sed 's/ \(By\|And\) /\L&/g' | perl -pe 's/_[a-f0-9]{30}//g')"
				echo "$imgFilename $attrib" >> "$dirAttribPath"
			fi

			thumbnailPath="$(getThumbnailPath "$imgPath")"
			thumbnailUrl="${thumbnailPath/#"$gitRoot"/}"
			thumbnailUrl="${thumbnailUrl// /%20}"

			# if this is a link, use the url from the file itself
			if [[ "$imgExt" == "link" ]]
			then
				imageUrl="$(cat "$imgPath")"
				imageUrl="${imageUrl// /%20}"
				imageUrlRawRoot="$raw_root$imageUrl"
			# otherwise use the url of the file
			else
				imageUrl="${imgPath/#"$gitRoot"/}"
				imageUrl="${imageUrl// /%20}"
				imageUrlRawRoot="$raw_root$imageUrl"
			fi

			subDirReadmeUrl="$subDir/README.MD"
			subDirReadmeUrl="${subDirReadmeUrl#"$gitRoot"}"
			subDirReadmeUrl="${subDirReadmeUrl// /%20}"

			subDirName="$(basename -- "$subDir" | perl -pe "$headerDirNameRegex")"
			customHeaderID="$(echo "${subDirName}" | perl -pe "$subDirIdRegex")"

			if [ -n "$attrib" ]
			then
				# strip markdown links out of the alt text
				alt_text=$(echo "$attrib" | sed 's/([^)]*)//g' | sed 's/[][]//g')
			else
				alt_text="$imgFilename"
			fi

			subDirPathReggie="$(quoteRe "${subDir}/")"

			subDirCount="$(echo "$imgFiles" | grep -iPc "$subDirPathReggie")"

			subDirHeader="## [$subDirName]($subDirReadmeUrl) - $subDirCount"

			# if [[ "$dirReadmePath" == "$rootReadmePath" ]]
			# then
					#
			# fi

			# show full image for bottom level dirs
			# TODO support dirs with images at depth 1 *and* sub dirs
			if [[ "$bottomLevelDir" == 1 ]]
			then

				# TODO handle .link files differently

				mdText+="[![$alt_text]($imageUrl \"$alt_text\")]($imageUrlRawRoot)"

				# have to do a bunch of shenanigans to get the attribution immediately below the picture
				if [ -n "$attrib" ]
				then
					mdText+="\\"$'\n'
					mdText+="$attrib"$'\n'
				else
					mdText+=$'\n'
				fi
					mdText+=$'\n'

			#thumbnails only
			else

				if ! echo "$mdText" | grep -qP "^$(quoteRe "${subDirHeader}")\$"
				then
					# adding an HTML anchor for persistent header links
					# since 1) github flavored markdown does not support markdown custom header ID syntax and 2) the auto headers include the file count
					mdText+=$'\n'
					mdText+="<a id=\"${customHeaderID}\"></a>"$'\n'
					mdText+=$'\n'
					mdText+="${subDirHeader}"$'\n'
				fi

				mdText+="[![$alt_text]($thumbnailUrl \"$alt_text\")]($imageUrl)"$'\n'

			fi

			echo -en '\r'

		# if [[ "$i" -gt 50 ]]
		# then
		# 	echo "breaking early for testing"
		# 	break
		# fi

		done < <( echo "$subDirImgFiles" )
	done < <( echo "$subDirs" )

	parentDirUrl="$(echo "$friendlyDirName" | sed -r -e 's|/[^/]+$||' -e 's/ /%20/g')"
	mdText+=$'\n'$'\n'
	mdText+="[back to top](#)"$'\n'
	mdText+="[up one level]($parentDirUrl/README.MD)"$'\n'
	mdText+="[home](/)"

	# only write if changed
	if [[ -f "$dirReadmePath" ]]
	then
		mdTextOld="$(cat "$dirReadmePath")"
	else
		mdTextOld=''
	fi


	if [[ "$mdTextOld" != "$mdText" ]]
	then
		echo "$mdText" > "$dirReadmePath"

		# echo
		# echo "mdText:    $(echo "$mdText" | wc)"
		# echo "mdTextOld: $(echo "$mdTextOld" | wc)"
	else
		# gotta update the mod time
		# if we got here then readme mod time < dir mod time
		# so we need to update the mod time to avoid having to reconstruct (but not write) the file perpetually
		touch "$dirReadmePath"
		iMdUnchanged=$((iMdUnchanged + 1))
	fi

done < <( echo "$directories" )

echo
echo "$iMdSkip/$totalDirs md files skipped"
echo "$iMdUnchanged/$totalDirs md files unchanged"

# build the root table of contents
pathRootEscaped="$(quoteRe "$gitRoot/")"
rootDirs="$(echo "$imgFilesAll" | sed "s/^$pathRootEscaped//g" | grep -iPo '^[^/]+' | sort -u)"
yearDirCount="$(echo "$rootDirs" | grep -iP '(^(19|20)\d\d|(19|20)\d\d$)' | wc -l)"

echo "$rootDirs" | while read -r rootDir
do
	rootDirEscaped="$(echo "$rootDir" | perl -pe 's/ /%20/g')"
	echo "- [$rootDir](/$rootDirEscaped/README.MD) - $(find-images "$gitRoot/$rootDir" | wc -l | numfmt --grouping)" >> "$tocMD"
	# echo $'\n' >> "$tocMD"
done

# unless there are several year directories at the root, sort by number of images
# otherwise leave the default alphabetical sort
if [[ "$yearDirCount" -lt 3 ]]
then
	tocText="$(cat "$tocMD" | sort -rn -t '-' -k3)"
else
	tocText="$(cat "$tocMD")"
fi

rm "$tocMD"

if [[ -d "$gitRoot/mobile" ]]
then
	mobileSize="$(du "$gitRoot/mobile" --max-depth 0 --human-readable | cut -f1)"
fi

# if the main readme template does not exist...
if [[ ! -f "$readmeTemplatePath" ]]
then
	# use the gallery project's default template
	if [[ -f "$readmeTemplateDefaultPath" ]]
	then
		cat "$readmeTemplateDefaultPath" > "$readmeTemplatePath"
	# or a simple template if the default is missing
	else
		echo $'# {total} {repo name cap}\n\n{table of contents}' > "$readmeTemplatePath"
	fi
fi

if [[ -f "$readmeTemplatePath" ]]
then
	readmeTemplate="$(cat "$readmeTemplatePath")"
fi

readmeTemplate="${readmeTemplate//\{table of contents\}/"$tocText"}" 
readmeTemplate="${readmeTemplate//\{mobile size\}/"$mobileSize"}" 
readmeTemplate="${readmeTemplate//\{total\}/"$(numfmt --grouping "$totalImages")"}" 
readmeTemplate="${readmeTemplate//\{repo name\}/"${repoName,,}"}" 
readmeTemplate="${readmeTemplate//\{repo name cap\}/"$repoNameCap"}" 
readmeTemplate="${readmeTemplate//\{repo url\}/"$repoUrl"}" 

# only write if changed
if [[ -f "$homeReadmePath" ]]
then
	mdTextOld="$(cat "$homeReadmePath")"
else
	mdTextOld=''
fi

# generate banners for the main page if missing
makeBannersPath="$thisScriptDir/scripts/make_banners.sh"
if [[ -e "$makeBannersPath" ]]
then
	"$makeBannersPath"
else
	echo "make_banners.sh not found"
fi

if [[ "$mdTextOld" != "$readmeTemplate" ]]
	then
	echo "$readmeTemplate" > "$homeReadmePath"
fi

homeReadmeHtmlPath="${gitRoot}/README.html"
indexHtmlPath="${gitRoot}/index.html"

# if pandoc is installed, convert the markdown files to html for easy preview and debugging
if type pandoc >/dev/null 2>&1
then
	echo "--updating readme html's..."
	mdFiles=$(find "$gitRoot" -type f -iname '*.md' -not -path '*/.*' -not -iname 'attrib.md' "${excludeGalleryMaker[@]}" | sort -t'/' -k1,1 -k2,2 -k3,3 -k4,4 -k5,5 -k6,6 -k7,7)

	i=0
	iHtmlSkip=0
	total=$(echo "$mdFiles" | wc -l)

	while read -r src
	do
		((i++)) || true
		descname="$(basename -- "$(dirname -- "$src")")/$(basename -- "$src")"

		printf '\033[2K%4d/%d: %s...' "$i" "$total" "$descname" | cut -c "-$COLUMNS" | tr -d $'\n'

		htmlPath="${src%.*}.html"
		# skip if the underlying md hasn't changed since last html generation
		if [[ "$htmlPath" -nt "$src" ]]
		then
			iHtmlSkip=$((iHtmlSkip + 1))
			echo -en '\r'
			continue
		fi

		if [ -f "$htmlPath" ]
		then
			rm "$htmlPath"
		fi
		metaTitle="${src%.*}"
		metaTitle="${metaTitle#"$gitRoot"}"
		metaTitle="${metaTitle#/}"
		metaTitle="$(echo "$metaTitle" | sed 's|/README$||g')"
		mdDir="$(dirname -- "$src")"
		bottomLevelDir="$(bottom-level-dir "$mdDir")"

		if [[ "${mdDir,,}" = "${gitRoot,,}" ]]
		then
			metaTitle="${repoName^}"
			cssPath="$cssPathBigImages"
		elif [[ "$bottomLevelDir" == 1 ]]
		then
			cssPath="$cssPathBigImages"
		else
			cssPath="$cssPathTinyImages"
		fi

		metaTitle="$(echo "$metaTitle" | perl -pe 's/_/ /g')"

		htmlText=$(pandoc --from=gfm --to=html --standalone --css="$cssPath" --metadata title="$metaTitle" "$src")
		htmlText="${htmlText//.md/.html}"
		htmlText="${htmlText//.MD/.html}"
		htmlText="${htmlText//"$raw_root"/}"

		# remove that double header
		htmlText="$(echo "$htmlText" | perl -00pe 's|<header.+?title-block-header.+?</header>||gs')"

		echo "$htmlText" > "$htmlPath"

		echo -en "\r"

	done < <( echo "$mdFiles")

	# echo ""

	if [[ "$iHtmlSkip" -gt 0 ]]
	then
		echo
		echo "skipped $iHtmlSkip/$total html files"
	fi

	# update an index file matching readme.html
	if [[ -f "$homeReadmeHtmlPath" ]] && [[ "$homeReadmeHtmlPath" -nt "$indexHtmlPath" || ! -f "$indexHtmlPath" ]]
	then
		cp "$homeReadmeHtmlPath" "$indexHtmlPath"
	fi

fi

# TODO exclude files already added
if [[ -z "$lfsFiles" ]]
then
	lfsFilesCount=0
else
	lfsFilesCount="$(echo "$lfsFiles" | wc -l)"
fi

# need to specify in MBs coz otherwise a large gap is created by the rounding
largeFiles="$(find-images "$gitRoot" -size +"$githubFileMaxBytes"c -size -"$githubLfszMaxBytes"c | (grep -wvf <(echo "$lfsFiles") || true))"
if [[ -z "$largeFiles" ]]
then
	largeFilesCount=0
else
	largeFilesCount="$(echo "$largeFiles" | wc -l)"
fi

tooLargeFiles="$(find-images "$gitRoot" -size +"$githubLfszMaxBytes"c)"
if [[ -z "$tooLargeFiles" ]]
then
	tooLargeFilesCount=0
else
	tooLargeFilesCount="$(echo "$tooLargeFiles" | wc -l)"
fi

echo

if [[ "$lfsFilesCount" -gt 0 ]]
then
	echo "$lfsFilesCount files stored in Git LFS"
fi
if [[ "$largeFilesCount" -gt 0 ]]
then
	echo "$largeFilesCount files too large for Guthib! Consider compressing them or uploading elsewhere and linking."
fi
if [[ "$tooLargeFilesCount" -gt 0 ]]
then
	echo "$tooLargeFilesCount files are too large for Guthib LFS!"
fi

# echo "$lfsFiles" > lfsFiles.log
# echo "$largeFiles" > largeFiles.log
# echo "$tooLargeFiles" > tooLargeFiles.log

echo
echo "done at $(date)"
