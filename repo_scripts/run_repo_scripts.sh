#!/usr/bin/env bash

set -e

# echo filename
basename "${0%.*}"

tempDir="$1"

if [[ -z "$tempDir" ]]
then
  echo "please provide the temp dir to use for repo mod operations"
  exit 1
fi

shortRemoteName="$(git remote -v | grep -iP 'origin' | grep -iPo '[^/:]+/[^/]+(?= )' | perl -pe 's/\.git$//g' | head -n1)"
repoUrl="$(git remote get-url --all origin | head -n 1)"
repoName="${shortRemoteName#*/}"
tempRepoDir="$tempDir/$repoName"
galleryMakerUrl="https://github.com/buckmanc/gallery_maker"
tempGalleryMakerDir="$tempDir/gallery_maker"

if [[ -z "$repoUrl" ]]
then
  echo "could not identify remote repo"
  echo "current dir: $PWD"
  exit 1
fi

mkdir -p "$tempDir"

if [[ ! -d "$tempRepoDir" ]]
then
  git -C "$tempDir" clone "$repoUrl" "$tempRepoDir"
fi

cd "$tempRepoDir"

# attempt to cleanup potential dirty repos
rm -f ".git/index.lock"
git merge --abort 2> /dev/null || true
git checkout .
git clean -f .
git remote prune origin

if [[ ! -d "$tempGalleryMakerDir" ]]
then
  git -C "$tempDir" clone "$galleryMakerUrl" "$tempGalleryMakerDir"
fi

git -C "$tempGalleryMakerDir" checkout .
git -C "$tempGalleryMakerDir" clean -f
git -C "$tempGalleryMakerDir" pull origin main

"$tempGalleryMakerDir/repo_scripts/update_update_mod_time.sh" --commit
"$tempGalleryMakerDir/repo_scripts/update_cloudflare_branch.sh"
