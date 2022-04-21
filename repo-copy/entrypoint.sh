#!/bin/sh

set -e
set -x

if [ -z "$INPUT_FILES" ]
then
  echo "::error::No files to copy provided"
  return 1
fi

echo "::group::Setting Up Git"
USERNAME="kienle-ci"
git config --global user.email "$INPUT_USER_EMAIL"
git config --global user.name "$INPUT_USER_USERNAME"
echo "✅ Git Setup Complete"
echo "::endgroup::"

echo "::group::Purging Temp Directory"
TEMP_DIR="../temp-repo"
mkdir -p "$TEMP_DIR"
chmod -R +w $TEMP_DIR
rm -r "$TEMP_DIR"
echo "✅ Temp Directory Purged"
echo "::endgroup::"

echo "::group::Cloning Public Repository"
{
	git clone --single-branch --branch "$INPUT_DESTINATION_BRANCH" "https://x-access-token:$INPUT_USER_TOKEN@github.com/$INPUT_DESTINATION_NAME.git" "$TEMP_DIR"
} || {
	echo "::error::Could not clone the destination repository. Command:"
	echo "::error::git clone --single-branch --branch $INPUT_DESTINATION_BRANCH https://x-access-token:$INPUT_USER_TOKEN@github.com/$INPUT_DESTINATION_NAME.git $TEMP_DIR"
	echo "::error::Please verify that the target repository exist AND that it contains the destination branch name, and is accesible by your provided API token"
	exit 1
}
echo "✅ Repo Cloned"
echo "::endgroup::"

echo "::group::Ensuring Destination Directory Exists"
echo "Note: This is only required for first-time use"
mkdir -p "$TEMP_DIR/$INPUT_DESTINATION_FOLDER"
echo "Destination Directory Verified"
echo "::endgroup::"

echo "::group::Copying Public Destination to Temp Folder"
cp -r $INPUT_FILES ../$TEMP_DIR/$INPUT_DESTINATION_FOLDER/
echo "✅ Files Copied to ../$TEMP_DIR/$INPUT_DESTINATION_FOLDER"
echo "::endgroup::"

echo "::group::Ensure Directory is Safe"
git config --global --add safe.directory "../$TEMP_DIR"
echo "✅ Temp Directory is Safe"
echo "::endgroup::"

echo "::group::Checking In Files"
cd "../$TEMP_DIR"
git add .
echo "✅ Files Checked In"
echo "::endgroup::"

echo "::group::Committing and Pushing Files"
PARSED_COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE:-'CI: Copy Files from External Repo'}"
if git status | grep -q "Changes to be committed"
then
  git commit --message "$PARSED_COMMIT_MESSAGE"
  git push -u origin HEAD:"$INPUT_DESTINATION_BRANCH"
  echo "✅ Files Committed and Pushed"
else
  echo "✅ No Changed Detected, Skipped Commit and Push"
fi

echo "::endgroup::"

echo "✅ Copying Complete, see you next time 👋 "
