#!/bin/bash

source ./setup.sh

query=$1
item=$(
  cat <<EOF
{
  uid: .id,
  title: .full_name,
  subtitle: "Open \(.html_url)",
  arg: .html_url,
  autocomplete: .full_name,
  mods: {
    alt: {
      arg: .ssh_url,
      subtitle: "Copy clone command with \(.ssh_url)"
    },
    "shift+alt": {
      arg: .clone_url,
      subtitle: "Copy clone command with \(.clone_url)"
    },
    ctrl: {
      arg: "\(.html_url)/actions",
      subtitle: "Open \(.html_url)/actions"
    },
    cmd: {
      arg: .full_name,
      subtitle: "List open pull requests"
    }
  },
  text: {
    copy: .html_url
  }
}
EOF
)

# Always fetch in parallel and merge results (user repos + search results if query present)

tmp_user=$(mktemp)
tmp_search=$(mktemp)
cleanup() { rm -f "$tmp_user" "$tmp_search"; }
trap cleanup EXIT

# User repos (filtered locally with grep if query provided)
(
  gh api /user/repos --method GET \
    -f sort=pushed \
    --hostname "$API_HOST" \
    --cache "$CACHE_USER_REPOS" \
    --paginate \
    --jq ".[] | $item" | { if [[ -n "$query" ]]; then grep -i "$query" || true; else cat; fi; } >"$tmp_user"
) &
pid_user=$!

# Search endpoint (only if query provided, otherwise skip to save API calls)
if [[ -n "$query" ]]; then
  (
    gh api /search/repositories --method GET \
      --hostname "$API_HOST" \
      -f q="$query in:name archived:false" \
      -F per_page=9 \
      -f sort=pushed \
      --cache "$CACHE_SEARCH_REPOS" \
      --jq ".items.[] | $item" >"$tmp_search"
  ) &
  pid_search=$!
fi

wait "$pid_user" 2>/dev/null || true
if [[ -n "$pid_search" ]]; then
  wait "$pid_search" 2>/dev/null || true
fi

# Combine, remove blanks, unique by uid (id) preserving first occurrence
items_array=$(cat "$tmp_user" "$tmp_search" 2>/dev/null | awk 'NF' | jq -s 'unique_by(.uid)')

echo -n "{\"items\":$items_array}"
