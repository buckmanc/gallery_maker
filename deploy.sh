#!/usr/bin/env bash

# convenience script

gitRoot="$(git rev-parse --show-toplevel)"
repoName="$(basename "$gitRoot" | perl -pe 's/_/\-/g')"
repoName="${repoName,,}"

if rclone sync "$gitRoot" r2:"$repoName"/ --filter-from rclone_filter --progress --stats-one-line
then
	txtme "$repoName deploy complete"
else
	txtme "$repoName deploy failed"
fi
