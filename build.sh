#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

APP=build/MiniCat.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -target arm64-apple-macos13 -o build/MiniCat-arm64 main.swift
swiftc -O -target x86_64-apple-macos13 -o build/MiniCat-x86_64 main.swift
lipo -create build/MiniCat-arm64 build/MiniCat-x86_64 -output "$APP/Contents/MacOS/MiniCat"
rm build/MiniCat-arm64 build/MiniCat-x86_64

cp Resources/*.png "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>MiniCat</string>
    <key>CFBundleIdentifier</key><string>local.minicat</string>
    <key>CFBundleExecutable</key><string>MiniCat</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
