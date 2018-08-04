#!/bin/bash
set -e

# This script is meant to run on Travis-CI only
if [ -z "$TRAVIS_BRANCH" ]; then
  echo "ABORTING: this script runs on Travis-CI only"
  exit 1
fi

# Check essential envs
if [ -z "$GITHUB_TOKEN" ]; then
  echo "ABORTING: env GITHUB_TOKEN is missing"
  exit 1
fi
if [ -z "$GITHUB_OAUTH_TOKEN" ]; then
  echo "ABORTING: env GITHUB_OAUTH_TOKEN is missing"
  exit 1
fi

# Verbose logging
set -x

# Create a build number
export BUILD_NR="$(date '+%Y%m%d-%H%M%S')"
echo "BUILD_NR=$BUILD_NR"

# Run build steps
# Create build directory
BUILD_DEST=builds/$BUILD_NR
mkdir -p $BUILD_DEST

# Build image
VERSION=v$BUILD_NR make shellcheck
VERSION=v$BUILD_NR make sd-image

# Test image
VERSION=v$BUILD_NR make test

# Prep the build to go to Github releases if we're on the master branch
if [ "$TRAVIS_BRANCH" == "master"]; then
  # Move artifacts to build dest
  mv hypriotos-rpi64* $BUILD_DEST/

  # Deploy to GitHub releases
  export GIT_TAG=v$BUILD_NR
  export GIT_RELTEXT="Auto-released by [Travis-CI build #$TRAVIS_BUILD_NUMBER](https://travis-ci.org/$TRAVIS_REPO_SLUG/builds/$TRAVIS_BUILD_ID)"
  curl -sSL https://github.com/tcnksm/ghr/releases/download/v0.5.4/ghr_v0.5.4_linux_amd64.zip > ghr.zip
  unzip ghr.zip
  ./ghr --version
  ./ghr --debug -u troyfontaine -b "$GIT_RELTEXT" $GIT_TAG builds/$BUILD_NR/
fi
