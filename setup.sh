#!/bin/bash

machine="$(/usr/bin/uname -m)"

if [[ "${machine}" == "arm64" ]]; then
  prefix="/opt/homebrew"
else
  prefix="/usr/local"
fi

export PATH="$prefix/bin:$PATH"
export API_HOST=${API_HOST:-github.com}
export CACHE_PULLS=${CACHE_PULLS:-10m}
export CACHE_SEARCH_REPOS=${CACHE_SEARCH_REPOS:-24h}
export CACHE_USER_REPOS=${CACHE_USER_REPOS:-72h}

if ! command -v gh &> /dev/null; then
  open "https://github.com/edgarjs/github-repos-alfred-workflow/blob/master/README.md"
  exit 0
fi
