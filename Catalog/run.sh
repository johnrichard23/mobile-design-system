#!/bin/zsh
# Builds the catalog app for the iOS simulator and launches it.
#
#   Catalog/run.sh                 # booted simulator, component list
#   Catalog/run.sh buttons         # open one page (see CatalogPage)
#   SIM=<udid> Catalog/run.sh      # a specific simulator
#   THEME=sample Catalog/run.sh    # the sample Figma theme
set -euo pipefail

root=${0:A:h:h}
out=$root/.build/catalog
app=$out/DesignSystemCatalog.app
sim=${SIM:-booted}
bundle_id=dev.designsystem.catalog

mkdir -p $app
xcrun --sdk iphonesimulator swiftc \
    -swift-version 6 \
    -target arm64-apple-ios17.0-simulator \
    -parse-as-library \
    -module-name DesignSystemCatalog \
    -o $app/DesignSystemCatalog \
    $root/Sources/DesignSystem/**/*.swift $root/Catalog/*.swift

# Loose images (e.g. the sample brand icon) go next to the executable.
cp $root/Catalog/Assets/*.png $app/ 2>/dev/null || true

cat > $app/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>$bundle_id</string>
    <key>CFBundleExecutable</key><string>DesignSystemCatalog</string>
    <key>CFBundleName</key><string>DS Catalog</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleSupportedPlatforms</key><array><string>iPhoneSimulator</string></array>
    <key>MinimumOSVersion</key><string>17.0</string>
    <key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
    <key>UILaunchScreen</key><dict/>
</dict>
</plist>
PLIST

args=()
[[ -n ${1:-} ]] && args+=(-page $1)
[[ -n ${THEME:-} ]] && args+=(-theme $THEME)

xcrun simctl terminate $sim $bundle_id 2>/dev/null || true
xcrun simctl install $sim $app
xcrun simctl launch $sim $bundle_id "${args[@]}"
