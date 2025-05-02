#!/usr/bin/env bash

set -e

gitRoot="$(git rev-parse --show-toplevel)"
thisScriptDir="$(dirname -- "$0")"
shortRemoteName="$(git remote -v | grep -iP '(github|origin)' | grep -iPo '[^/:]+/[^/]+(?= )' | perl -pe 's/\.git$//g' | head -n1)"
raw_root="https://raw.githubusercontent.com/$shortRemoteName/main"

# the goal here is to stay within the cloudflare filesize and file amount limits
# (25MB and 20k files)
# by linking to the main files hosted on github

gitStat="$(git status --porcelain --ignore-submodules)"
if [[ -n "$gitStat" ]]
then
  echo "repo is not clean!"
  exit 1
fi

# switch to cloudflare branch as necessary
git fetch --all
git switch cloudflare_page || git switch -c cloudflare_page

# merge main branch changes
git pull origin cloudflare_page
git merge main -X theirs || true

conflictedFileCount="$(git ls-files --unmerged | wc -l)"
if [[ "$conflictedFileCount" -gt 0 ]]
then
  # burn any merge conflicts that make it through
  while read -r path
  do
	ext="${path##*.}"
	ext="${ext,,}"

	# if it's a known gallery content type, burn it
	if [[ "$ext" =~ ^(3gp|avi|mp4|m4v|mpg|mov|wmv|webm|mkv|vob|jpe?g|png|gif|link)$ ]]
	then
	  git rm "$path"
	# otherwise add it and let it (possibly) fall subject to below alterations
	else
	  git add "$path"
	fi

  done < <( git ls-files --unmerged | perl -pe 's/^.+?\t//g' | sort -u)

  git commit -m "auto resolve merge conflict"
fi

# delete all images and video from main directory
"$thisScriptDir/../scripts/find-images-or-videos" "$gitRoot" -not -ipath '*/.*' | xargs --no-run-if-empty -d '\n' git rm --ignore-unmatch
# delete all markdown files?
find "$gitRoot" -type f -iname '*.md' | xargs --no-run-if-empty -d '\n' git rm --ignore-unmatch

# repoint all links (not embedded images) to the raw github url
git ls-files | grep -iP '\.html$' | xargs --no-run-if-empty -d '\n' perl -i -pe 's@href="\/(?!(\.|.*?readme\.html|.*?README\.html))@href="'"$raw_root"'/@g'
git ls-files | grep -iP '\.html$' | xargs --no-run-if-empty -d '\n' git add

gitStat="$(git status --porcelain --ignore-submodules)"
if [[ -n "$gitStat" ]]
then
  # commit
  git commit -m "automatically adjust for cloudflare page"
  git push origin cloudflare_page
else
  echo "no changes"
fi
