#!/bin/sh
# Keep native tool and runtime discovery relative to the installed SDK root.
exec "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/build/bin/neboc" "$@"
