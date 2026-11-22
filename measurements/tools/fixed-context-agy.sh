#!/usr/bin/env bash
# usage: fixed-context-agy.sh <root> [model] — measures the context an agy delegate sends on its
# first request: runs `agy -p` twice from <root> with a one-word answer, once plain and once under
# bwrap masking skills, plugins and mcp_config.json with --disable-slash-commands, and prints each
# run's input tokens. Spends two short calls of the model (default gemini-3.8-flash-high) from the
# user's quota.
set -eu
root=$(cd "${1:?usage: fixed-context-agy.sh <root> [model]}" && pwd)
model=${2:-gemini-3.8-flash-high}
settings='{"agentMode":"","enableTerminalSandbox":false}'
prompt="Answer with the single word: ok"

(cd "$root" && agy -p "$prompt" --model "$model" --output-format json --settings "$settings") |
  jq -r '"full: \(.usage.input_tokens) tokens in (\(.usage.output_tokens) out, \(.usage.thinking_tokens) thinking)"'

base=$(mktemp -d -p /tmp)
mkdir "$base/tmp" "$base/empty"
printf '{}' >"$base/mcp_config.json"
agy_state=~/.gemini/antigravity-cli
xdg-dbus-proxy "$DBUS_SESSION_BUS_ADDRESS" "$base/bus" --filter --talk=org.freedesktop.secrets &
proxy=$!
trap 'kill $proxy 2>/dev/null || true; rm -rf "$base"' EXIT
for _ in $(seq 50); do [ -S "$base/bus" ] && break; sleep 0.1; done

jail=(bwrap --ro-bind / / --dev /dev --proc /proc --bind "$base/tmp" /tmp
  --bind "$agy_state" "$agy_state"
  --tmpfs "$XDG_RUNTIME_DIR" --ro-bind "$base/bus" "$XDG_RUNTIME_DIR/bus"
  --setenv XDG_CACHE_HOME /tmp/cache)
for d in ~/.gemini/config/skills ~/.gemini/config/plugins "$agy_state/builtin/skills" "$agy_state/builtin/plugins"; do
  [ -d "$d" ] && jail+=(--ro-bind "$base/empty" "$d")
done
[ -e ~/.gemini/config/mcp_config.json ] && jail+=(--ro-bind "$base/mcp_config.json" ~/.gemini/config/mcp_config.json)

"${jail[@]}" --unshare-all --share-net --die-with-parent --chdir "$root" \
  agy -p "$prompt" --model "$model" --dangerously-skip-permissions --disable-slash-commands \
    --output-format json --settings "$settings" |
  jq -r '"lean: \(.usage.input_tokens) tokens in (\(.usage.output_tokens) out, \(.usage.thinking_tokens) thinking)"'
