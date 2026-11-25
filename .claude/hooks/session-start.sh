#!/bin/bash
set -euo pipefail

# Only run in Claude Code cloud sessions
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# OmniRoute needs Node.js >= 22.22.2; the container ships an older 22.x, so install Node 24
NODE_VERSION="v24.14.1"
NODE_DIR="${NODE24_DIR:-/opt/node24}"

if [ "$("$NODE_DIR/bin/node" -v 2>/dev/null || true)" != "$NODE_VERSION" ]; then
  tmp="$(mktemp -d)"
  tarball="node-$NODE_VERSION-linux-x64.tar.xz"
  curl -sSfL "https://nodejs.org/dist/$NODE_VERSION/$tarball" -o "$tmp/$tarball"
  curl -sSfL "https://nodejs.org/dist/$NODE_VERSION/SHASUMS256.txt" \
    | grep " $tarball\$" | (cd "$tmp" && sha256sum -c -)
  rm -rf "$NODE_DIR" && mkdir -p "$NODE_DIR"
  tar -xJf "$tmp/$tarball" -C "$NODE_DIR" --strip-components=1
  rm -rf "$tmp"
fi

export PATH="$NODE_DIR/bin:$PATH"

# Make Node 24 the default for the rest of the session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$NODE_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# Install OmniRoute (unified AI router) under Node 24 if missing
if [ ! -x "$NODE_DIR/bin/omniroute" ]; then
  npm install -g omniroute
fi
