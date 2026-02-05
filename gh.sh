#!/bin/bash

source "$(dirname "$0")/setup.sh"

query=$1
item=$(
  cat <<'EOF'
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

empty_result='{"items":[]}'

err=$(mktemp) || {
  printf '%s' "$empty_result"
  exit 0
}

repos=$(gh api /user/repos --method GET \
  -f sort=pushed \
  -F per_page=100 \
  --hostname "$API_HOST" \
  --cache "$CACHE_USER_REPOS" \
  --paginate \
  --jq "[.[] | $item]" 2>"$err")
gh_exit=$?
err_msg=$(<"$err")
rm -f "$err"

if [[ $gh_exit -ne 0 ]]; then
  if [[ -n "$err_msg" ]]; then
    printf '%s\n' "$err_msg" >&2
  fi
  printf '%s' "$empty_result"
  exit 0
fi

# --paginate outputs one JSON array per page; merge them and optionally filter
if [[ -n "$query" ]]; then
  # Use --arg to safely pass query into jq (no injection possible)
  repos=$(printf '%s\n' "$repos" | jq -s --arg q "$query" \
    '[add // [] | .[] | select(.title | ascii_downcase | contains($q | ascii_downcase))]') \
    || repos="[]"
else
  repos=$(printf '%s\n' "$repos" | jq -s 'add // []') || repos="[]"
fi

# Check if we got results
has_results=$(printf '%s' "$repos" | jq 'length > 0' 2>/dev/null)

# Fall back to search if no local match and query is present
if [[ "$has_results" != "true" && -n "$query" ]]; then
  # Sanitize query: allowlist of safe characters only
  safe_query=$(printf '%s' "$query" | tr -cd 'a-zA-Z0-9 ._-')

  if [[ -n "$safe_query" ]]; then
    err=$(mktemp) || {
      printf '%s' "$empty_result"
      exit 0
    }

    repos=$(gh api /search/repositories --method GET \
      --hostname "$API_HOST" \
      -f q="$safe_query in:name archived:false" \
      -F per_page=9 \
      -f sort=pushed \
      --cache "$CACHE_SEARCH_REPOS" \
      --jq "[.items[] | $item]" 2>"$err")
    gh_exit=$?
    err_msg=$(<"$err")
    rm -f "$err"

    if [[ $gh_exit -ne 0 ]]; then
      if [[ -n "$err_msg" ]]; then
        printf '%s\n' "$err_msg" >&2
      fi
      repos="[]"
    fi
  fi

  if [[ -z "$repos" ]]; then
    repos="[]"
  fi
fi

# Final output with jq fallback
printf '%s' "$repos" | jq -c '{items: .}' 2>/dev/null || printf '%s' "$empty_result"
