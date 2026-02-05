#!/bin/bash

machine="$(/usr/bin/uname -m)"

if [[ "${machine}" == "arm64" ]]; then
  prefix="/opt/homebrew"
else
  prefix="/usr/local"
fi

export PATH="$prefix/bin:$PATH"
export API_HOST="${API_HOST:-github.com}"
export CACHE_PULLS="${CACHE_PULLS:-10m}"
export CACHE_SEARCH_REPOS="${CACHE_SEARCH_REPOS:-24h}"
export CACHE_USER_REPOS="${CACHE_USER_REPOS:-72h}"

# Validate API_HOST: must be a valid hostname (alphanumeric, dots, hyphens)
if [[ ! "$API_HOST" =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]]; then
  printf '%s' '{"items":[{"title":"Invalid API_HOST","subtitle":"API_HOST must be a valid hostname (e.g. github.com)","valid":false}]}'
  exit 0
fi

if ! command -v gh &> /dev/null; then
  printf '%s' '{"items":[{"title":"GitHub CLI not found","subtitle":"Press Enter to open installation instructions","arg":"https://github.com/edgarjs/github-repos-alfred-workflow/blob/master/README.md"}]}'
  exit 0
fi

if ! command -v jq &> /dev/null; then
  printf '%s' '{"items":[{"title":"jq not found","subtitle":"Press Enter to open installation instructions","arg":"https://formulae.brew.sh/formula/jq"}]}'
  exit 0
fi
