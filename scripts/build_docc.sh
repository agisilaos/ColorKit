#!/bin/bash

# Script to build the DocC documentation for ColorKit
# Usage: ./scripts/build_docc.sh

echo "Building ColorKit DocC documentation..."

# Create derived data directory if it doesn't exist
mkdir -p ./DerivedData

# Build the documentation - use iPhone 16 simulator
xcodebuild docbuild \
  -scheme ColorKit \
  -derivedDataPath ./DerivedData \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'

# Check if the build was successful
if [ -d "./DerivedData/Build/Products/Debug-iphonesimulator/ColorKit.doccarchive" ]; then
  echo "✅ DocC documentation built successfully!"
  echo "Documentation available at: ./DerivedData/Build/Products/Debug-iphonesimulator/ColorKit.doccarchive"
  echo "You can open it with: open ./DerivedData/Build/Products/Debug-iphonesimulator/ColorKit.doccarchive"
else
  echo "❌ Error: DocC documentation failed to build"
  exit 1
fi

# Optional: Automatically open the documentation
read -p "Do you want to open the documentation now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  open ./DerivedData/Build/Products/Debug-iphonesimulator/ColorKit.doccarchive
fi 