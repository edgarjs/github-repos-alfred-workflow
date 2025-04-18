#!/bin/bash -e

OUTPUT="github-repos.alfredworkflow"
mkdir -p build
cp clear-cache.sh gh.sh icon.png info.plist pulls.sh setup.sh build/
cd build
zip $OUTPUT -r . -qq
ls | grep -v "$OUTPUT" | xargs rm -r
echo "Done -> $OUTPUT"
