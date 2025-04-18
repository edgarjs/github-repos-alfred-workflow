#!/bin/bash

source ./setup.sh

repo=$1
repo_url="https://$API_HOST/$repo"
item=$(
  cat <<EOF
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

pulls=$(gh api "/repos/$repo/pulls" --method GET \
  -f per_page=9 \
  --hostname "$API_HOST" \
  --cache "$CACHE_PULLS" \
  --jq ".[] | $item")

items=$(echo -n "$pulls" | tr '\n', ',' | sed 's/,$//')

cat <<EOF
{
  "items": [
    {
      "title": "Open pull requests page",
      "subtitle": "Open $repo_url/pulls",
      "arg": "$repo_url/pulls"
    }
    $(if [[ -n "$items" ]]; then echo ','; fi)
    $items
  ]
}
EOF
