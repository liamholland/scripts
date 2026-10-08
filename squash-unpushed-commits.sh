#!/bin/bash

#############################################################################
# this script squashes commits made on the current branch up to a dynamically
# selected point. this is either the last merge commit, be it the main branch
# or some other merge or the last commit which was pushed to the remote
# repository. you can either supply a commit message or it will use the last
# provided one. you can also tell the script the name of the base branch, or
# you can just let it use the main/master branch by default
# USAGE: squash.sh [message] [branch name]
#############################################################################


num_commits_to_squash=0
branch_name=$(git branch --show-current)

echo "_"
echo "|  squashing commits on branch '${branch_name}'"

if [ -z "$2" ]; then
    echo "|  no branch supplied, assuming branch is based on main or master"

    if [ `git rev-parse --verify main 2>/dev/null` ]; then
        base_branch="main"
    elif [ `git rev-parse --verify master 2>/dev/null` ]; then
        base_branch="master"
    else
        echo "|  no main branch, please supply the branch name, aborting..."
        echo "X"
        exit 1
    fi
else
    base_branch="$2"
    if ! [ `git rev-parse --verify "$base_branch" 2>/dev/null` ]; then
        echo "|  base branch '${base_branch}' does not exist, aborting..."
        echo "X"
        exit 1
    fi
fi
echo "|  branch is based on '${base_branch}'"

# check if there is a remote branch
if [ `git rev-parse --verify origin/$branch_name 2>/dev/null` ]; then
    last_origin_commit=$(git rev-parse origin/$branch_name)
    num_commits_to_squash=$(git rev-list $last_origin_commit..HEAD --count)
else
    echo "|  no remote instance of branch '${branch_name}'"
    num_commits_to_squash=$(git rev-list $base_branch..$branch_name --count) 
fi

last_merge_commit=$(git log --merges -n 1 --pretty=%H)
if [ -z "$last_merge_commit" ]; then
    num_commits_since_last_merge=10000
else
    num_commits_since_last_merge=$(git rev-list $last_merge_commit..HEAD --count)
fi

merge_limit=""
if [ "$num_commits_since_last_merge" -lt "$num_commits_to_squash" ]; then
    num_commits_to_squash=$num_commits_since_last_merge
    merge_limit="(cutoff at last merge)"
fi

echo "|  ${num_commits_to_squash} valid local commits have been made ${merge_limit}"

if [ "$num_commits_to_squash" -lt 2 ]; then
    echo "|  not enough commits to squash (${num_commits_to_squash}), aborting..."
    echo "X"
    exit 1
fi

echo "|  squashing ${num_commits_to_squash} commits"

if [ -z "$1" ]; then
    commit_message="$(git log -1 --pretty=%B)"
    echo "|  no commit message supplied, using message of most recent commit"
else
    commit_message="$1"
fi

echo "|  commit message: ${commit_message}"

git reset --soft HEAD~$num_commits_to_squash
git add .
echo "| -"
git commit -am "$commit_message" 2>&1 | sed  's/^/| | /'
echo "| v"

echo "v"
