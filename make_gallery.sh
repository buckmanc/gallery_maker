#!/usr/bin/env bash
set -e

# heavily modified from github.com/jonascarpay/Wallpapers

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

# echo "shortRemoteName: $shortRemoteName"

tocMD="${gitRoot}/.internals/tableofcontents.md"
cssPathBigImages="/.internals/bigimages.css"
cssPathTinyImages="/.internals/tinyimages.css"
thumbnails_dir="$gitRoot/.internals/thumbnails"
thumbnails_old_dir="$gitRoot/.internals/thumbnails_old"
readmeTemplatePath="$gitRoot/.internals/README_template.md"
readmeTemplateDefaultPath="$thisScriptDir/.internals/README_template.md"
fileListDir="$gitRoot/.internals/filelist"
fileListFile="$fileListDir/${branchName}.log"
fileListFileMain="$fileListDir/main.log"

headerDirNameRegex='s/^(\d{2}|[zZ][xyzXYZ])[ \-_]{1,3}//g'
subDirIdRegex='s/[ \-_"#]+/-/g'

rm "$tocMD" > /dev/null 2>&1 || true

update-script() {

	filename="$1"
	homePath="$HOME/bin/$filename"
	scriptsPath="$thisScriptDir/scripts/$filename"
	if [[ -f "$homePath" && "$gitRoot" == "$thisScriptDir" ]]
	then
		cp "$homePath" "$scriptsPath"
	fi
}

update-script "find-images"
update-script "find-videos"
update-script "find-images-or-videos"
update-script "wallpaper-magick"

find-images() {
	"$thisScriptDir/scripts/find-images-or-videos" "$@" -not -path '*/thumbnails*' -not -path '*/scripts/*' -not -type l -not -path '*/temp *'
}
find-images-main() {
	find-images "$gitRoot" -mindepth 3 -not -path '*/.*'
}
find-images-including-thumbnails() {
	"$thisScriptDir/scripts/find-images-or-videos" "$@" -not -path '*/scripts/*' -not -type l -not -path '*/temp *'
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
	if [[ "$2" == "--old" ]]
	then
		optOld=1
	fi

	ext="${path##*.}"
	ext="${ext,,}"

	if [[ "$optOld" == 0 ]]
	then
		target="${thumbnails_dir}/${path#"$gitRoot/"}"
	else
		target="${thumbnails_old_dir}/${path#"$gitRoot/"}"
	fi

	newExt=''

	# if it's a known movie type, make a gif thumbnail
	if [[ "$ext" =~ ^(3gp|avi|mp4|m4v|mpg|mov|wmv|webm|mkv|vob) ]]
	then
		target="$(echo "$target" | perl -pe 's/\.[^\.]+?$/.gif/g')"
	# otherwise, limit thumbnail types
	elif ! [[ "$ext" =~ ^(jpe?g|png|gif) ]]
	then
		target="$(echo "$target" | perl -pe 's/\.[^\.]+?$/.png/g')"
	fi

	echo "$target"
}

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
		shortPath="${path/#"$gitRoot"/}"
		# only use perceptual hash filenames for specific folders
		# only misc folders at one level deep
		if echo "$shortPath" | grep -qiP "(/forests/|/space/|/space - fictional/|^/?[^/]+/misc/|/leaves/|/cityscapes/)" && ! echo "$filename" | grep -qiP '^[a-f0-9]{16}_'
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
webpFiles="$(find "$gitRoot" -type f -iname '*.webp' -not -ipath '*/.internals/thumbnails/*')"
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
unhappyFiles="$(find-images-including-thumbnails -iregex '.*/[_-]+.*')"
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


echo "--updating thumbnails..."

mkdir -p "$thumbnails_dir"
mkdir -p "$fileListDir"
mv "$thumbnails_dir" "$thumbnails_old_dir"
mkdir -p "$thumbnails_dir"


imgFilesAll="$(find-images-main)"
i=0
totalImages=$(echo "$imgFilesAll" | wc -l)

echo "$imgFilesAll" | while read -r src; do
	((i++)) || true
	filename="$(basename -- "$src")"
	printf '\033[2K%4d/%d: %s...' "$i" "$totalImages" "$filename" | cut -c "-$COLUMNS" | tr -d $'\n'

	target="$(getThumbnailPath "$src")"
	thumbnail_old="$(getThumbnailPath "$src" --old)"

	target_dir="$(dirname -- "$target")"
	mkdir -p "$target_dir"

	if [[ ! -f "$thumbnail_old" ]]; then
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

		# echo
		# echo "aspectRatio: $aspectRatio"
		# echo "targetDimensions: $targetDimensions"

		fitCaret="^"
		bgColor="none"

		# altered logic for images that sit in the center
		if echo "$src" | grep -iq "/floaters/"
		then
			fitCaret=""
			bgColor="black"
		# altered logic for terminal images, which are 2/3 alpha and 1/3 black bg anyway
		elif echo "$src" | grep -iq "/terminal/"
		then
			bgColor="black"
		fi

		# resize images, then crop to the desired resolution
		# write a filler image on failure
	convert -background "$bgColor" -dispose none -auto-orient -thumbnail "${targetDimensions}${fitCaret}" -unsharp 0x1.0 -gravity Center -extent "$targetDimensions" -layers optimize +repage "$src"[0-30] "$target" \
		|| convert -background transparent -fill white -size "$targetDimensions" -gravity center -stroke black -strokewidth "4" caption:"?" "$target"

		echo    "${src#"$gitRoot"}~$(date +%s)" >> "$fileListFile"

		echo ""
	else
		mv "$thumbnail_old" "$target"
		echo -en "\r"
	fi
done

rm -rf "$thumbnails_old_dir"
# sort the file list to contain only the most recent entry per file
cat "$fileListFile" | sort -t~ -k1,2r | sort -t~ -k1,1 -u | sponge "$fileListFile"

echo ""

echo "--updating readme md's..."

homeReadmePath="${gitRoot}/README.MD"
rootReadmePath="${gitRoot}/README_ALL.MD"

# min depth > 0 disables the generation of readme_all / rootReadmePath
directories="$(find "$gitRoot" -mindepth 1 -type d -not -path '*/.*' -not -path '*/scripts' -not -path '*/temp *' -not -path '*/thumbnails_test')"
totalDirs="$(echo "$directories" | wc -l)"
i=0
iDir=0
iMdUnchanged=0
iMdSkip=0
while read -r dir; do
	((iDir++)) || true
	printf -v dirStatus '\033[2K%3d/%d:' "$iDir" "$totalDirs"
	friendlyDirName="${dir/"$gitRoot"}"
	thumbDir="$gitRoot/.internals/thumbnails/$friendlyDirName"

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

	imgFiles="$(find-images "$dir" -not -path '*/.*' -not -path '*/scripts')"
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
			imageUrl="${imgPath/#"$gitRoot"/}"
			imageUrl="${imageUrl// /%20}"
			imageUrlRawRoot="$raw_root$imageUrl"

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
	mdText+="[up one level]($parentDirUrl/README.MD)"

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
readmeTemplate="${readmeTemplate//\{repo name cap\}/"${repoName^}"}" 
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
	mdFiles=$(find "$gitRoot" -type f -iname '*.md' -not -path '*/.*' -not -iname 'attrib.md' | sort -t'/' -k1,1 -k2,2 -k3,3 -k4,4 -k5,5 -k6,6 -k7,7)

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
lfsFiles="$(git -C "$gitRoot" lfs ls-files)"
largeFiles="$("$thisScriptDir/scripts/find-images-or-videos" "$gitRoot" -not -ipath '*/.*' -size +100M | wc -l)"

if [[ "$largeFiles" -gt 0 ]]
then
	echo
	echo "$largeFiles are larger than Guthib's size limit. Add them to lfs with scripts/lfs_add.sh"
fi

echo
echo "done at $(date)"
