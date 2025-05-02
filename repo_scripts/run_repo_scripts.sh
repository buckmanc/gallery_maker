#!/usr/bin/env bash

set -e

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

mkdir -p "$tempDir"

if [[ ! -d "$tempRepoDir" ]]
then
  git -C "$tempDir" clone --recurse-submodules "$repoUrl" "$tempRepoDir"
fi

cd "$tempRepoDir"

# attempt to cleanup potential dirty repos
rm -f ".git/index.lock"
git checkout .
git clean -f .

"$tempRepoDir/gallery_maker/repo_scripts/update_update_mod_time.sh" --commit
"$tempRepoDir/gallery_maker/repo_scripts/update_cloudflare_branch.sh"
