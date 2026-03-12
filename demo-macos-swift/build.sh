#!/bin/bash
# Build script for macOS SwiftUI Demo

set -e

echo "Building 3D Detection Algorithm - macOS Demo..."

# Compile the Swift app
swiftc -o Demo3DDetection \
    -target arm64-apple-macos12.0 \
    -import-objc-header /dev/null \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    Demo3DDetectionApp.swift

echo "Build complete! Run with: ./Demo3DDetection"
