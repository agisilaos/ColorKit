#!/bin/bash

# Script to build and serve the DocC documentation for ColorKit
# Usage: ./scripts/serve_docc.sh

echo "Building and serving ColorKit DocC documentation..."

# Create derived data directory if it doesn't exist
mkdir -p ./DerivedData

# Build the documentation - use iPhone 16 simulator
xcodebuild docbuild \
  -scheme ColorKit \
  -derivedDataPath ./DerivedData \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'

# Check if the build was successful
DOCC_PATH="./DerivedData/Build/Products/Debug-iphonesimulator/ColorKit.doccarchive"
if [ ! -d "$DOCC_PATH" ]; then
  echo "❌ Error: DocC documentation failed to build"
  exit 1
fi

echo "✅ DocC documentation built successfully!"
echo "Serving documentation at http://localhost:8000/"

# Use Python's built-in HTTP server to serve the documentation
echo "Starting HTTP server..."
echo "Press Ctrl+C to stop the server"

# Open the browser first
open "http://localhost:8000/"

# Change to the documentation directory and start the server
cd "$DOCC_PATH"
python3 -m http.server 8000 