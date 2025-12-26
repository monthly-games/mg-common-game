#!/bin/bash
# MG-Games Batch Icon Generator
#
# Generates icons for all 52 games in the mg-games project.
#
# Usage:
#   ./tools/batch_generate_icons.sh [base_path]
#
# Each game should have:
#   - game/assets/icon.png (1024x1024 app icon)
#   - game/assets/splash.png (optional, splash image)
#   - game/icon_config.json (optional, custom configuration)
#
# icon_config.json format:
# {
#   "icon": "assets/icon.png",
#   "background": "#FF5722",
#   "splash": "assets/splash.png"
# }

set -e

BASE_PATH="${1:-d:/mg-games/repos}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎨 MG-Games Batch Icon Generator"
echo "================================="
echo "📁 Base Path: $BASE_PATH"
echo ""

# Default colors for games (can be customized per game)
declare -A GAME_COLORS=(
    ["mg-game-0001"]="#4CAF50"  # Green
    ["mg-game-0002"]="#2196F3"  # Blue
    ["mg-game-0003"]="#FF5722"  # Deep Orange
    ["mg-game-0004"]="#9C27B0"  # Purple
    ["mg-game-0005"]="#FF9800"  # Orange
    ["mg-game-0006"]="#E91E63"  # Pink
    ["mg-game-0007"]="#00BCD4"  # Cyan
    ["mg-game-0008"]="#795548"  # Brown
    ["mg-game-0009"]="#607D8B"  # Blue Grey
    ["mg-game-0010"]="#8BC34A"  # Light Green
)

# Function to generate icons for a single game
generate_game_icons() {
    local game_dir="$1"
    local game_name=$(basename "$game_dir")

    echo "----------------------------------------"
    echo "📱 Processing $game_name..."

    local game_path="$game_dir/game"

    if [ ! -d "$game_path" ]; then
        echo "   ⚠️  No game directory found, skipping..."
        return
    fi

    # Check for icon
    local icon_path=""
    if [ -f "$game_path/assets/icon.png" ]; then
        icon_path="assets/icon.png"
    elif [ -f "$game_path/assets/images/icon.png" ]; then
        icon_path="assets/images/icon.png"
    elif [ -f "$game_path/assets/app_icon.png" ]; then
        icon_path="assets/app_icon.png"
    else
        echo "   ⚠️  No icon found, creating placeholder..."
        mkdir -p "$game_path/assets"
        # Create a simple placeholder (requires ImageMagick)
        if command -v convert &> /dev/null; then
            local color="${GAME_COLORS[$game_name]:-#4CAF50}"
            convert -size 1024x1024 xc:"$color" \
                -gravity center -pointsize 200 -fill white \
                -annotate 0 "${game_name: -2}" \
                "$game_path/assets/icon.png"
            icon_path="assets/icon.png"
            echo "   ✓ Created placeholder icon with color $color"
        else
            echo "   ❌ ImageMagick not found, cannot create placeholder"
            return
        fi
    fi

    # Determine background color
    local bg_color="${GAME_COLORS[$game_name]:-#FFFFFF}"

    # Check for custom config
    if [ -f "$game_dir/icon_config.json" ]; then
        # Parse JSON config (requires jq)
        if command -v jq &> /dev/null; then
            local custom_icon=$(jq -r '.icon // empty' "$game_dir/icon_config.json")
            local custom_bg=$(jq -r '.background // empty' "$game_dir/icon_config.json")

            [ -n "$custom_icon" ] && icon_path="$custom_icon"
            [ -n "$custom_bg" ] && bg_color="$custom_bg"
        fi
    fi

    echo "   🖼️  Icon: $icon_path"
    echo "   🎨 Background: $bg_color"

    # Generate config files
    cat > "$game_path/flutter_launcher_icons.yaml" << EOF
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "$icon_path"
  min_sdk_android: 21
  remove_alpha_ios: true
  adaptive_icon_background: "$bg_color"
  adaptive_icon_foreground: "$icon_path"
EOF

    cat > "$game_path/flutter_native_splash.yaml" << EOF
flutter_native_splash:
  color: "$bg_color"
  image: "$icon_path"
  android_12:
    color: "$bg_color"
    image: "$icon_path"
  ios: true
  android: true
EOF

    echo "   ✓ Generated configuration files"

    # Optionally run flutter commands (commented out for batch processing)
    # cd "$game_path"
    # flutter pub get
    # flutter pub run flutter_launcher_icons
    # flutter pub run flutter_native_splash:create
}

# Process all games
success_count=0
skip_count=0
error_count=0

for i in $(seq -w 1 52); do
    game_dir="$BASE_PATH/mg-game-00$i"
    if [ ${#i} -eq 1 ]; then
        game_dir="$BASE_PATH/mg-game-000$i"
    fi

    if [ -d "$game_dir" ]; then
        if generate_game_icons "$game_dir"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    else
        echo "⚠️  Directory not found: $game_dir"
        ((skip_count++))
    fi
done

echo ""
echo "================================="
echo "📊 Summary"
echo "   ✅ Success: $success_count"
echo "   ⚠️  Skipped: $skip_count"
echo "   ❌ Errors: $error_count"
echo ""
echo "Next steps:"
echo "1. Create icon.png (1024x1024) in each game's assets folder"
echo "2. Run 'flutter pub get' in each game"
echo "3. Run 'flutter pub run flutter_launcher_icons' in each game"
echo "4. Run 'flutter pub run flutter_native_splash:create' in each game"
