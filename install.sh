#!/bin/bash
set -e

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
BUILD_DIR="$APP_DIR/build"

mkdir -p "$BIN_DIR" "$APP_DESKTOP_DIR" "$ICON_DIR"

# 1. Configure & build native C++/Qt6 binary
if ! command -v cmake >/dev/null 2>&1; then
    echo "Error: cmake is required to build Omarchy Slitherlink." >&2
    exit 1
fi

GENERATOR=()
if command -v ninja >/dev/null 2>&1; then
    GENERATOR=(-G Ninja)
fi

cmake -S "$APP_DIR" -B "$BUILD_DIR" "${GENERATOR[@]}" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR"

if [[ ! -x "$BUILD_DIR/omarchy-slitherlink" ]]; then
    echo "Error: build did not produce $BUILD_DIR/omarchy-slitherlink" >&2
    exit 1
fi

# 2. Launcher in ~/.local/bin (sets project root so QML/data resolve)
cat << LAUNCHER > "$BIN_DIR/omarchy-slitherlink"
#!/bin/bash
export OMARCHY_SLITHERLINK_ROOT="$APP_DIR"
exec "$BUILD_DIR/omarchy-slitherlink" "\$@"
LAUNCHER
chmod +x "$BIN_DIR/omarchy-slitherlink"

# 3. Install icon
cp "$APP_DIR/data/org.omarchy.slitherlink.svg" "$ICON_DIR/org.omarchy.slitherlink.svg"

# 4. Install desktop entry
cp "$APP_DIR/data/org.omarchy.slitherlink.desktop" "$APP_DESKTOP_DIR/org.omarchy.slitherlink.desktop"

# 5. Update desktop database and icon cache if tools are present
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APP_DESKTOP_DIR" || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo "Successfully installed Omarchy Slitherlink (native C++/Qt6)!"
echo "You can launch it with: omarchy-slitherlink or from the Omarchy app launcher."
