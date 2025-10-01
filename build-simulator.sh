#!/bin/bash
set -e

echo "🔨 Building for iOS Simulator (Vision Only Mode)"
echo "⚠️  Note: MLKit is not supported in simulator builds"
echo ""

# Clean derived data
echo "🧹 Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Scan_OCR_KTP-*

# Build the project
echo "🏗️  Building project..."
xcodebuild \
  -workspace "Scan OCR KTP.xcworkspace" \
  -scheme "Scan OCR KTP" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  EXCLUDED_ARCHS="x86_64" \
  ONLY_ACTIVE_ARCH=YES \
  build

echo ""
echo "✅ Build completed successfully!"
echo "ℹ️  Note: The app will run in Vision-only mode on simulator"
