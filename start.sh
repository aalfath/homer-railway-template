#!/bin/sh
# Railway wrapper for Homer: volume ownership, starter config, optional basic auth,
# then lighttpd in the foreground. Exits non-zero if lighttpd stops on its own,
# so Railway's ON_FAILURE restart policy brings the dashboard back.
set -eu

ASSETS=/www/assets
PORT="${PORT:-8080}"
export PORT

# 1. The Railway volume is mounted root-owned: hand it to the lighttpd user.
mkdir -p "$ASSETS"
chown -R 1000:1000 "$ASSETS" 2>/dev/null || true

# 2. First boot: copy Homer's default assets (icons, themes, tools) without
#    overwriting anything already on the volume, and install a starter config.
if [ ! -f "$ASSETS/config.yml" ]; then
  echo "railway: no config.yml on the volume, installing the default assets and a starter config"
  for SRC in /www/default-assets/* /www/default-assets/.[!.]*; do
    [ -e "$SRC" ] || continue
    DST="$ASSETS/$(basename "$SRC")"
    [ -e "$DST" ] || cp -R "$SRC" "$DST"
  done
  cp /www/railway-default-config.yml "$ASSETS/config.yml"
  chown -R 1000:1000 "$ASSETS"
fi

# 3. Optional: HOMER_CONFIG_YML holds the whole config.yml and replaces the file on every start.
if [ -n "${HOMER_CONFIG_YML:-}" ]; then
  echo "railway: writing config.yml from HOMER_CONFIG_YML"
  printf '%s\n' "$HOMER_CONFIG_YML" > "$ASSETS/config.yml"
  chown 1000:1000 "$ASSETS/config.yml"
fi

# 4. Basic auth is done in /railway-auth.lua from HOMER_USERNAME and HOMER_PASSWORD.
if [ -n "${HOMER_PASSWORD:-}" ]; then
  echo "railway: basic auth on (user ${HOMER_USERNAME:-admin})"
else
  echo "railway: HOMER_PASSWORD is empty, the dashboard is public"
fi

# 5. lighttpd in the foreground (it drops to the lighttpd user itself).
echo "railway: starting Homer $(cat /www/VERSION 2>/dev/null || true) on port $PORT"
lighttpd -D -f /lighttpd-railway.conf &
PID=$!
STOPPING=0
trap 'STOPPING=1; kill -TERM "$PID" 2>/dev/null' TERM INT
set +e
wait "$PID"; RC=$?
# wait returns early when a trapped signal arrives: wait again for lighttpd to finish.
if [ "$STOPPING" = 1 ]; then wait "$PID" 2>/dev/null; exit 0; fi
echo "railway: lighttpd stopped unexpectedly (exit $RC)" >&2
[ "$RC" = 0 ] && RC=1
exit "$RC"
