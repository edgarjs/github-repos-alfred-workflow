#!/bin/bash
set -euo pipefail

OUTPUT="github-repos.alfredworkflow"
rm -rf build
mkdir -p build
cp clear-cache.sh gh.sh gh.png icon.png info.plist pulls.sh setup.sh build/
cd build
zip "$OUTPUT" -r . -qq
shopt -s nullglob dotglob
for f in *; do [[ "$f" != "$OUTPUT" ]] && rm -rf "$f"; done
echo "Done -> $OUTPUT"
