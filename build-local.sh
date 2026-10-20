#!/bin/bash
# 本地一键构建 TIPA（需要 Mac + Xcode）
set -e
cd "$(dirname "$0")"
rm -rf build
xcodebuild -project ShiftAssistantComplete.xcodeproj \
  -scheme ShiftAssistantComplete \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/ShiftAssistantComplete.xcarchive \
  archive CODE_SIGNING_ALLOWED=NO
cd build
mkdir Payload
cp -R ShiftAssistantComplete.xcarchive/Products/Applications/ShiftAssistantComplete.app Payload/
zip -qr ShiftAssistant.tipa Payload
echo "完成：build/ShiftAssistant.tipa"
