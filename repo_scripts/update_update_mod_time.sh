#!/usr/bin/env bash

# echo filename
basename "${0%.*}"

# generates a script to update mod time on image files to match their last commit time
# this is the most viable option I could find to keep wallpapers from flooding the android gallery after every update
# previous versions restored disk mod times after updates
# but that was prone to failure

set -e

optCommit=0
if [[ "$1" == "--commit" ]]
then
	optCommit=1
fi

gitStat="$(git status --porcelain --ignore-submodules)"
if [[ -n "$gitStat" ]]
then
  echo "repo is not clean!"
  exit 1
fi

git switch main
git pull

gitRoot=$(git rev-parse --show-toplevel)
outPath="$gitRoot/.internals/update_mod_time.sh"
if [[ -f "$outPath" ]]
then
	currentText="$(cat "$outPath")"
else
	currentText=''
fi

loggy="$(git log)"

if echo "$loggy" | grep -Fiq '(grafted,' || ! echo "$loggy" | grep -Fiq 'initial commit'
then
	echo "entire git history is required to update the modification time update script"
	echo "this repository does not contain the full git history"
	exit 1
fi

outText+="#!/usr/bin/env bash"
outText+=$'\n\n'
outText+="if [[ ! -f .git/.nomedia ]]; then touch .git/.nomedia; fi"
outText+=$'\n\n'
outText+="echo \"updating file modification times...\""
outText+=$'\n\n'


files="$(git ls-files --deduplicate --exclude-standard --full-name | grep -Piv '^(\./)?\.internals/')"

while read -r src
do
	if [[ ! -f "$src" ]]
	then
		continue
	fi

	# skip anything that isn't an image or video
	mimeType="$(file --mime-type --brief -- "$src" | cut -d '/' -f1)"
	mimeType="${mimeType,,}"
	fileExt="${src##*.,,}"
	if [[ "$mimeType" != "image" && "$mimeType" != "video" && "$fileExt" != "md" && "$fileExt" != "html" ]]
	then
		continue
	fi

	# datey="$(date -r "$src" "+%F")"
	datey="$(git log -1 --format=%cd --date=iso -- "$src")"
	outText+="touch -c -d \"$datey\" \"$src\""$'\n'

done < <( echo "$files" )

# TODO fix this test
if [[ "$currentText" != "$outText" ]]
then
	echo "$outText" > "$outPath"
	if [[ "$optCommit" == 1 ]]
	then
		git add "$outPath"
		git commit -m "update mod time script" "$outPath" || true
		git push origin main
	fi
fi
