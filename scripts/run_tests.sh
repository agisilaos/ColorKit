#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🚀 Running ColorKit Tests..."

# Function to run tests
run_tests() {
    platform=$1
    destination=$2
    
    echo -e "\n${GREEN}Running tests for $platform...${NC}"
    
    if xcodebuild test \
        -scheme ColorKit \
        -destination "$destination" \
        -parallel-testing-enabled YES \
        -parallel-testing-worker-count 4 \
        -derivedDataPath ~/Library/Developer/Xcode/DerivedData \
        -enableCodeCoverage YES \
        | xcpretty; then
        echo -e "${GREEN}✅ $platform tests passed${NC}"
        return 0
    else
        echo -e "${RED}❌ $platform tests failed${NC}"
        return 1
    fi
}

# Run iOS tests
ios_result=0
run_tests "iOS" "platform=iOS Simulator,name=iPhone 16 Pro" || ios_result=$?

# Run macOS tests
macos_result=0
run_tests "macOS" "platform=macOS,arch=arm64" || macos_result=$?

# Check if any tests failed
if [ $ios_result -eq 0 ] && [ $macos_result -eq 0 ]; then
    echo -e "\n${GREEN}✅ All tests passed successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed${NC}"
    exit 1
fi 