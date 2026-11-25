#!/bin/sh
set -eu

# Avoid intermittent HTTP/2 stream resets from the module proxy. Limit this
# setting to downloads so application builds and runtime keep their defaults.
for attempt in 1 2 3; do
    if GODEBUG="${GODEBUG:+${GODEBUG},}http2client=0" go mod download; then
        exit 0
    fi

    if [ "$attempt" -lt 3 ]; then
        echo "Go module download failed (attempt $attempt/3); retrying..." >&2
        sleep "$attempt"
    fi
done

echo "Go module download failed after 3 attempts." >&2
exit 1
