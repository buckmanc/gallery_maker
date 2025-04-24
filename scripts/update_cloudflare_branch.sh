#!/usr/bin/env bash

set -e

gitRoot="$(git rev-parse --show-toplevel)"
shortRemoteName="$(git remote -v | grep -iP '(github|origin)' | grep -iPo '[^/:]+/[^/]+(?= )' | perl -pe 's/\.git$//g' | head -n1)"
raw_root="https://raw.githubusercontent.com/$shortRemoteName/main"

# the goal here is to stay within the cloudflare filesize and file amount limits
# (25MB and 20k files)
# by linking to the main files hosted on github

# TODO
# if there are dirty edits
# if interactive, warn and confirm
# if not interactive, throw an error

# switch to cloudflare branch as necessary
git switch cloudflare_page || git switch -c cloudflare_page
# merge main branch changes
git pull origin cloudflare_page
git fetch origin main:main
git merge main -X theirs

conflictedFileCount="$(git ls-files --unmerged | wc -l)"
if [[ "$conflictedFileCount" -gt 0 ]]
then
  # burn any merge conflicts that make it through
  git ls-files --unmerged | xargs --no-run-if-empty -d '\n' git rm
  git commit -m "auto resolve merge conflict"
fi

# delete all images and video from main directory
"$gitRoot/scripts/find-images-or-videos" "$gitRoot" -not -ipath '*/.*' | xargs --no-run-if-empty -d '\n' git rm --ignore-unmatch
# delete all markdown files?
find "$gitRoot" -type f -iname '*.md' | xargs --no-run-if-empty -d '\n' git rm --ignore-unmatch

# repoint all links (not embedded images) to the raw github url
git ls-files | grep -iP '\.html$' | xargs --no-run-if-empty -d '\n' perl -i -pe 's@href="\/(?!(\.|.*?readme\.html|.*?README\.html))@href="'"$raw_root"'/@g'
git ls-files | grep -iP '\.html$' | xargs --no-run-if-empty -d '\n' git add
# commit
git commit -m "automatically adjust for cloudflare page"
git push origin cloudflare_page

# TODO  warn when files are stored in github LFS, maybe add a symbol to the thumbnail
