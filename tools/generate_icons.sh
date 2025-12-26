#!/bin/bash
# MG-Games App Icon & Splash Generator (Shell Script)
#
# Generates all required app icons and splash screens for iOS and Android.
#
# Usage:
#   ./tools/generate_icons.sh [icon_path] [background_color]
#
# Examples:
#   ./tools/generate_icons.sh assets/icon.png
#   ./tools/generate_icons.sh assets/icon.png "#FF5722"

set -e

ICON_PATH="${1:-assets/icon.png}"
BG_COLOR="${2:-#FFFFFF}"
PROJECT_DIR="${3:-.}"

echo "🎨 MG-Games Icon Generator"
echo "=========================="
echo "📁 Project: $PROJECT_DIR"
echo "🖼️  Icon: $ICON_PATH"
echo "🎨 Background: $BG_COLOR"
echo ""

# Check if icon exists
if [ ! -f "$PROJECT_DIR/$ICON_PATH" ]; then
    echo "❌ Icon not found: $ICON_PATH"
    echo "   Please provide a valid icon path (at least 1024x1024 pixels)"
    exit 1
fi

# Check for ImageMagick
if ! command -v convert &> /dev/null; then
    echo "⚠️  ImageMagick not found. Using flutter_launcher_icons instead."
    USE_IMAGEMAGICK=false
else
    USE_IMAGEMAGICK=true
fi

# Generate flutter_launcher_icons.yaml
cat > "$PROJECT_DIR/flutter_launcher_icons.yaml" << EOF
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "$ICON_PATH"
  min_sdk_android: 21
  remove_alpha_ios: true
  adaptive_icon_background: "$BG_COLOR"
  adaptive_icon_foreground: "$ICON_PATH"
  web:
    generate: true
    image_path: "$ICON_PATH"
    background_color: "$BG_COLOR"
    theme_color: "$BG_COLOR"
EOF

echo "✓ Generated flutter_launcher_icons.yaml"

# Generate flutter_native_splash.yaml
cat > "$PROJECT_DIR/flutter_native_splash.yaml" << EOF
flutter_native_splash:
  color: "$BG_COLOR"
  image: "$ICON_PATH"
  android_12:
    color: "$BG_COLOR"
    image: "$ICON_PATH"
  ios: true
  android: true
  fullscreen: false
EOF

echo "✓ Generated flutter_native_splash.yaml"

# Check if packages are installed
cd "$PROJECT_DIR"

# Add packages if not present
if ! grep -q "flutter_launcher_icons" pubspec.yaml; then
    echo "📦 Adding flutter_launcher_icons..."
    flutter pub add flutter_launcher_icons --dev
fi

if ! grep -q "flutter_native_splash" pubspec.yaml; then
    echo "📦 Adding flutter_native_splash..."
    flutter pub add flutter_native_splash --dev
fi

# Run generators
echo ""
echo "🔧 Generating icons..."
flutter pub run flutter_launcher_icons

echo ""
echo "🌊 Generating splash screens..."
flutter pub run flutter_native_splash:create

echo ""
echo "✅ Icon generation complete!"
echo ""
echo "Generated files:"
echo "  iOS:"
echo "    - ios/Runner/Assets.xcassets/AppIcon.appiconset/*"
echo "    - ios/Runner/Assets.xcassets/LaunchImage.imageset/*"
echo "  Android:"
echo "    - android/app/src/main/res/mipmap-*/*"
echo "    - android/app/src/main/res/drawable/*"
