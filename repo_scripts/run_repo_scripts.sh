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

if [[ -z "$repoUrl" ]]
then
  echo "could not identify remote repo"
  echo "current dir: $PWD"
  exit 1
fi

mkdir -p "$tempDir"

if [[ ! -d "$tempRepoDir" ]]
then
  git -C "$tempDir" clone --recurse-submodules "$repoUrl" "$tempRepoDir"
fi

cd "$tempRepoDir"

# attempt to cleanup potential dirty repos
rm -f ".git/index.lock"
git merge --abort 2> /dev/null || true
git checkout .
git clean -f .

if [[ ! -d "$tempRepoDir/gallery_maker" ]]
then
  echo "gallery maker not present in remote repo"
  exit 1
fi

git -C "$tempRepoDir/gallery_maker" checkout .
git -C "$tempRepoDir/gallery_maker" pull origin main

"$tempRepoDir/gallery_maker/repo_scripts/update_update_mod_time.sh" --commit
"$tempRepoDir/gallery_maker/repo_scripts/update_cloudflare_branch.sh"
