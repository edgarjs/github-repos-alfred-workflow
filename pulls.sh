#!/bin/bash

source "$(dirname "$0")/setup.sh"

repo=$1
empty_result='{"items":[]}'

if [[ -z "$repo" || ! "$repo" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]; then
  printf '%s' "$empty_result"
  exit 0
fi

repo_url="https://$API_HOST/$repo"
item=$(
  cat <<'EOF'
{
  title: "PR #\(.number): \(.title)",
  subtitle: "Open \(.html_url)",
  arg: .html_url,
  text:{
    copy: .html_url
  }
}
EOF
)

err=$(mktemp) || {
  printf '%s' "$empty_result"
  exit 0
}

pulls=$(gh api "/repos/$repo/pulls" --method GET \
  -F per_page=9 \
  --hostname "$API_HOST" \
  --cache "$CACHE_PULLS" \
  --jq "[.[] | $item]" 2>"$err")
gh_exit=$?
err_msg=$(<"$err")
rm -f "$err"

if [[ $gh_exit -ne 0 ]]; then
  if [[ -n "$err_msg" ]]; then
    printf '%s\n' "$err_msg" >&2
  fi
  pulls="[]"
fi

if [[ -z "$pulls" ]]; then
  pulls="[]"
fi

# Build final JSON: prepend the "Open pull requests page" item, then append PR items
printf '%s' "$pulls" | jq -c --arg url "$repo_url/pulls" \
  '{items: ([{title: "Open pull requests page", subtitle: ("Open " + $url), arg: $url}] + .)}' \
  2>/dev/null || printf '%s' "$empty_result"
