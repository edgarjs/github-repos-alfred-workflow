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

repos=$(gh api /user/repos --method GET \
  -f sort=pushed \
  --hostname "$API_HOST" \
  --cache "$CACHE_USER_REPOS" \
  --paginate \
  --jq ".[] | $item" | grep -i "$query")

if [[ -z "$repos" ]]; then
  repos=$(gh api /search/repositories --method GET \
    --hostname "$API_HOST" \
    -f q="$query in:name archived:false" \
    -F per_page=9 \
    -f sort=pushed \
    --cache "$CACHE_SEARCH_REPOS" \
    --jq ".items.[] | $item")
fi

items=$(echo -n "$repos" | tr '\n', ',' | sed 's/,$//')

echo -n "{\"items\":[$items]}"
