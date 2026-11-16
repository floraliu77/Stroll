#!/bin/sh
# Redraws set walks' map lines along the streets, using Apple Maps walking directions between
# stops (needs internet). Saves them into each walk's "path" in stroll-content.json.
# Use: Tools/walk-routes.sh               (every walk)
#      Tools/walk-routes.sh steeples      (only these walks)
# Then run Tools/check-walk-model.sh, and look at the line in the Walks tab.
set -e
cd "$(dirname "$0")/.."
content="$PWD/Shared/Content/stroll-content.json"
tmp="${TMPDIR:-/tmp}"
swiftc -swift-version 5 -o "$tmp/stroll-walk-routes" Tools/WalkRoutes/main.swift
"$tmp/stroll-walk-routes" "$content" "$@" > "$tmp/stroll-walk-routes.json"
python3 - "$content" "$tmp/stroll-walk-routes.json" <<'PY'
import json, sys
content_path, routes_path = sys.argv[1], sys.argv[2]
content = json.load(open(content_path))
routes = json.load(open(routes_path))
for walk in content["walks"]:
    if walk["id"] in routes:
        walk["path"] = [{"latitude": lat, "longitude": lon} for lat, lon in routes[walk["id"]]]
        print(f"{walk['id']}: {len(walk['path'])} points along the streets")
open(content_path, "w").write(json.dumps(content, indent=2, ensure_ascii=False) + "\n")
PY
