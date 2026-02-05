#!/bin/bash

# Use := so empty string AND unset both trigger the default
CACHE_DIR="${CACHE_DIR:="$HOME/.cache/gh"}"

# Trim whitespace
CACHE_DIR=$(printf '%s' "$CACHE_DIR" | tr -d '[:space:]')

# Resolve symlinks and .. segments to canonical path (macOS compatible)
if [[ -d "$CACHE_DIR" ]]; then
  CACHE_DIR=$(cd "$CACHE_DIR" && /bin/pwd -P)
fi

# Block empty, root, or home-level paths
if [[ -z "$CACHE_DIR" || "$CACHE_DIR" == "/" ]]; then
  printf '%s' "Error: refusing to delete unsafe path: ${CACHE_DIR}" >&2
  exit 1
fi

# Require path is under $HOME/.cache (allowlist approach)
expected_prefix="$HOME/.cache"
if [[ "$CACHE_DIR" != "$expected_prefix"/* && "$CACHE_DIR" != "$expected_prefix" ]]; then
  printf '%s' "Error: CACHE_DIR must be under ${expected_prefix}: ${CACHE_DIR}" >&2
  exit 1
fi

rm -rf "$CACHE_DIR"

printf '%s' "${CACHE_DIR}"
