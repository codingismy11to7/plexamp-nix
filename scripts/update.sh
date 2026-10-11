#!/usr/bin/env bash
# Update sources.json to the latest Plexamp release from its Tauri update feed.
#
# Each AppImage is verified against the minisign signature in the feed using
# the updater public key embedded in the Plexamp binary (scripts/plexamp.pub)
# before its hash is recorded.
#
# Usage: scripts/update.sh [--check]
#   --check  only report whether an update is available (exit 1 if so)
#
# When run under GitHub Actions, writes current/latest/updated to $GITHUB_OUTPUT.
set -euo pipefail

FEED_URL="https://plexamp.plex.tv/desktop/tauri-update.json"

cd "$(dirname "$0")/.."
pubkey=$PWD/scripts/plexamp.pub

check_only=false
[[ ${1:-} == --check ]] && check_only=true

for tool in curl jq minisign nix; do
  command -v "$tool" >/dev/null || { echo "missing required tool: $tool" >&2; exit 2; }
done

output() { [[ -n ${GITHUB_OUTPUT:-} ]] && echo "$1=$2" >>"$GITHUB_OUTPUT"; return 0; }

feed=$(curl -fsSL --retry 3 "$FEED_URL")
latest=$(jq -er .version <<<"$feed")
current=$(jq -er .version sources.json)
output current "$current"
output latest "$latest"

if [[ $latest == "$current" ]]; then
  echo "plexamp is up to date ($current)"
  output updated false
  exit 0
fi

echo "plexamp update available: $current -> $latest"
if $check_only; then
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

new=$(jq --arg v "$latest" '.version = $v' sources.json)
for system in $(jq -r '.hashes | keys[]' sources.json); do
  feed_platform="linux-${system%-linux}"
  url=$(jq -er --arg p "$feed_platform" '.platforms[$p].url' <<<"$feed")
  jq -er --arg p "$feed_platform" '.platforms[$p].signature' <<<"$feed" | base64 -d >"$tmp/$system.minisig"

  echo "fetching $url"
  curl -fsSL --retry 3 -o "$tmp/$system.AppImage" "$url"
  minisign -V -q -p "$pubkey" -m "$tmp/$system.AppImage" -x "$tmp/$system.minisig"

  hash=$(nix hash file "$tmp/$system.AppImage")
  echo "$system: $hash"
  new=$(jq --arg s "$system" --arg h "$hash" '.hashes[$s] = $h' <<<"$new")
done

echo "$new" >sources.json
output updated true
echo "updated sources.json to $latest"
