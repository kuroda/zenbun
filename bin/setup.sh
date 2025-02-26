#!/bin/bash
set -eu

if [ -f "/usr/bin/docker" ] || [ -f "/usr/local/bin/docker" ]; then
  docker compose stop

  rm -rf _build deps

  gid=$(eval "id -g")

  if (( gid < 1000 )); then
    rgid=$(id -u)
  else
    rgid=${gid}
  fi

  docker compose build --build-arg UID=$(id -u) --build-arg GID=${rgid} app
  docker compose run --rm app /app/bin/setup.sh
else
  /app/bin/mix_deps_get.sh

  cd /app
  mix ecto.drop
  mix ecto.setup
fi
