#!/bin/sh

# If a command fails then the deploy stops
set -e
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
HEAD_HASH=`git rev-parse --verify HEAD` # latest commit hash
HEAD_HASH=${HEAD_HASH: -7} # get the last 7 characters of hash

# system requirements
sudo apt-get update
sudo apt-get install -y ruby ruby-dev gem

# python requirements
pip install pipenv
pipenv install

# ruby requirements
bundle install

# generation of community file
if [ "$1" != "skip_gen" ]; then
	printf "Generating community file"
	pipenv run python3 update-community.py
else
	printf "Skipping community file generation"
fi

# weekly reports/evaluation reports
pipenv run python3 update-reports.py
printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# remove old site
rm -rf ./docs

# Build the project
bundle exec jekyll build -d docs

# setup subtree pushing
git fetch
git worktree add docs netlify

if [ "$CI" = "true" ]; then
	git config user.name "GitHub Action"
	git config user.email "user@example.com"
fi
# Push source and build repos
if [ "$1" != "no_push" ]  && [ "$2" != "no_push" ] 
then
	printf "Pushing to GitHub"

	# Commit changes.
	msg="Auto deploy commit ${HEAD_HASH} to Netlify at ${date}"
	(cd docs; git add .)
	(cd docs; git diff-index --quiet HEAD || git commit -am "$msg")

	git push origin netlify
else
	printf "Skipping push to GitHub"
fi
