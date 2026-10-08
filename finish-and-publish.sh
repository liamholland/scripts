#!/bin/bash

#################################################################################
# script which will squash all commits and push the result to the
# remote instance of the branch.
# depends on the squash-unpushed-commits.sh script.
# see https://github.com/liamholland/scripts/blob/main/squash-unpushed-commits.sh
#################################################################################

squash_script_dep="squash-unpushed-commits.sh"
curr_dir="$(dirname "${BASH_SOURCE[0]}")"
commit_message="$1"

echo "_"
echo "| squashing commits and publishing to remote branch"

if ! [ -f "$curr_dir/$squash_script_dep" ]; then
    echo -e "| this script depends on squash-unpush-commits.sh\n| see https://github.com/liamholland/scripts/blob/main/squash-unpushed-commits.sh"
    echo "X"
    exit 1
fi

bash "$curr_dir/$squash_script_dep" "$commit_message" | sed  's/^/| /'

echo "| branch squashed... moving to publishing"

branch_name=$(git branch --show)
echo "| _"
git push origin "$branch_name" 2>&1 | sed  's/^/| | /'

if [ "$?" -gt 0 ]; then
    echo "| X"
    echo -e "failed to publish - aborting...\nX"
    exit 1
else
    echo "| v"
fi

echo "v"
