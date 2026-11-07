#!/bin/sh
# Checks the content file, then compiles the watch's walk logic and the phone's exploring session
# for this Mac and runs each through a scripted walk. Needs only the Swift command-line tools.
set -e
cd "$(dirname "$0")/.."
export STROLL_CONTENT="$PWD/Shared/Content/stroll-content.json"
tmp="${TMPDIR:-/tmp}"
swiftc -swift-version 5 -o "$tmp/stroll-content-check" Shared/StrollContent.swift Shared/Finds.swift Tools/ContentCheck/main.swift
"$tmp/stroll-content-check" "$PWD"
swiftc -swift-version 5 -o "$tmp/stroll-walk-check" Shared/StrollContent.swift Shared/Finds.swift Shared/RemoteMessages.swift Watch/WalkModel.swift Tools/WalkModelCheck/main.swift
"$tmp/stroll-walk-check"
swiftc -swift-version 5 -o "$tmp/stroll-explore-check" Shared/StrollContent.swift Shared/Finds.swift Shared/RemoteMessages.swift Phone/Walk/ExploreSession.swift Phone/Walk/DemoWalk.swift Tools/ExploreSessionCheck/main.swift
"$tmp/stroll-explore-check"
