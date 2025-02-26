#!/bin/bash
set -eu

if [ -f "/usr/bin/docker" ] || [ -f "/usr/local/bin/docker" ]; then
  docker compose run --rm app /app/bin/mix_deps_get.sh
else
  export HEX_HTTP_CONCURRENCY=1
  export HEX_HTTP_TIMEOUT=120
  cd /app
  mix deps.get
  MIX_ENV=test mix deps.get
  mix compile
fi
