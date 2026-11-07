#!/bin/sh
# Compiles the walk logic for this Mac and runs it through a scripted walk.
# Needs only the Swift command-line tools, not Xcode.
set -e
cd "$(dirname "$0")/.."
out="${TMPDIR:-/tmp}/stroll-walk-check"
swiftc -swift-version 5 -o "$out" Shared/Finds.swift Shared/RemoteMessages.swift Watch/WalkModel.swift Tools/WalkModelCheck/main.swift
"$out"
