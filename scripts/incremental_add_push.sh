#!/usr/bin/env bash

# a script to keep commits and pushes under githubs 2gb push limit
githubFileMaxBytes=98000000
githubPushMaxBytes=1980000000
githubLfszMaxBytes=1980000000

set -e

gitRoot="$(git rev-parse --show-toplevel)"

optDir=''
optMessage=''
optNextIsMessage=''

for arg in "$@"
do
  if [[ "$optNextIsMessage" == 1 && "$arg" == "-"* ]]
  then
    optNextIsMessage=0
  fi

  if [[ "$arg" == "--message" || "$arg" == "-m" ]]
  then
    optNextIsMessage=1
  elif [[ "$optNextIsMessage" == 1 ]]
  then
    optMessage="$arg"
    optNextIsMessage=0
  elif [[ "$arg" == "-"* ]]
  then
    echo "i have no idea what $arg means"
    exit 1
  elif [[ -e "$arg" ]]
  then
    optDir="$arg"
  else
    echo "i have no idea what $arg is"
    exit 1
  fi
done

if [[ -z "$optDir" ]]
then
  optDir="$gitRoot"
fi

if [[ -z "$optMessage" ]]
then
  echo "need a commit message"
  exit 1
fi

git reset .
git pull
git push
batchSize=0
commitCount=0

# "add" deleted files first
# to clear the road for checks for existent files
git ls-files "$optDir" --deleted --exclude-standard -z | xargs -0 git rm

# get files ordered by size desc
# specifically, only untracked and modified files in the provided dir
# ...but the size ordering is only per batch without more considerations
files="$(git ls-files "$optDir" --others --modified --exclude-standard -z | xargs -0 ls -S)"

while read -r file
do
  if [[ -z "$file" || ! -f "$file" ]]
  then
    continue
  fi

  fileSize="$(stat -c %s "$file")"

  # skip any file over the max
  if [[ "$fileSize" -gt "$githubPushMaxBytes" || "$fileSize" -gt "$githubFileMaxBytes" ]]
  then
    continue
  fi

  batchSize=$((batchSize+fileSize))

  if [[ "$batchSize" -ge "$githubPushMaxBytes" ]]
  then
    commitCount=$((commitCount+1))
    git commit -m "$optMessage - $commitCount"
    # two attempts on failure
    git push || git push
    batchSize="$fileSize"
  fi

  # git lfs free tier has a total storage max of 10GB
  # this is prohibitive
  # if [[ "$fileSize" -gt "$githubFileMaxBytes" ]]
  # then
  #   git lfs track --filename "$file"
  #   git add "$gitRoot/.gitattributes"
  # fi

  git add "$file"

done < <(echo "$files")

# do another commit to catch the remainder if necessary
if [[ -n "$(git ls-files --stage)" ]]
then
    commitCount=$((commitCount+1))
    git commit -m "$optMessage - $commitCount"
    # two attempts on failure
    git push || git push
fi
