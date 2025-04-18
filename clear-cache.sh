#!/bin/bash

CACHE_DIR="${CACHE_DIR:-"$HOME/.cache/gh"}"

rm -rf "$CACHE_DIR"

echo -n "${CACHE_DIR}"
