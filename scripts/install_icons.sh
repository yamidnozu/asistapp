#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/install_icons.sh /path/to/flutter_app_icons

SRC_DIR=${1:-}
if [[ -z "$SRC_DIR" ]]; then
  echo "Usage: $0 /path/to/flutter_app_icons"
  exit 2
fi

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Source directory not found: $SRC_DIR"
  exit 2
fi

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd -P)

backup() {
  local dest="$1"
  if [[ -e "$dest" ]]; then
    local ts=$(date +%Y%m%d%H%M%S)
    echo "Backing up $dest -> ${dest}.backup.$ts"
    mv "$dest" "${dest}.backup.$ts"
  fi
}

echo "Installing icons from $SRC_DIR"

# Android: copy mipmap-*/ files
for d in "$SRC_DIR"/mipmap-*; do
  if [[ -d "$d" ]]; then
    name=$(basename "$d")
    target="$REPO_ROOT/android/app/src/main/res/$name"
    mkdir -p "$target"
    echo "Copying from $d to $target"
    cp -v "$d"/* "$target/"
    # also copy/copy-to expected name for Android manifest
    # also copy/copy-to expected name for Android manifest
    # If the source had launcher_icon (older naming), ensure we have ic_launcher (preferred)
    # Do not add launcher_icon fallback – we prefer ic_launcher and remove old launcher_icon files from repo.
  fi
done

# iOS: AppIcon.appiconset
if [[ -d "$SRC_DIR/iOS/AppIcon.appiconset" ]]; then
  target="$REPO_ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
  mkdir -p "$target"
  echo "Copying iOS icons to $target"
  cp -v "$SRC_DIR/iOS/AppIcon.appiconset"/* "$target/"
fi

# Windows: app_icon.ico
if [[ -f "$SRC_DIR/app_icon.ico" ]]; then
  target="$REPO_ROOT/windows/runner/resources/app_icon.ico"
  echo "Copying windows icon to $target"
  backup "$target"
  cp -v "$SRC_DIR/app_icon.ico" "$target"
fi

# Generate a multi-resolution ICO for Windows from the largest available Android mipmap (requires ImageMagick)
if ! [[ -f "$REPO_ROOT/windows/runner/resources/app_icon.ico" ]]; then
  ICON_SRC=""
  # Prefer app icon asset (512x512) if present — gives us a 256 frame for ICO
  if [[ -f "$REPO_ROOT/assets/icon/app_icon.png" ]]; then
    ICON_SRC="$REPO_ROOT/assets/icon/app_icon.png"
  else
    # prefer xxxhdpi, then xxhdpi, xhdpi, hdpi, mdpi
    for p in mipmap-xxxhdpi mipmap-xxhdpi mipmap-xhdpi mipmap-hdpi mipmap-mdpi; do
    if [[ -f "$REPO_ROOT/android/app/src/main/res/$p/ic_launcher.png" ]]; then
      ICON_SRC="$REPO_ROOT/android/app/src/main/res/$p/ic_launcher.png"
      break
    fi
    # older naming 'launcher_icon.png' is deprecated; prefer ic_launcher
  done
  fi

  if [[ -n "$ICON_SRC" ]]; then
    if command -v magick >/dev/null 2>&1; then
      echo "Generating app_icon.ico from $ICON_SRC using magick"
      TMPDIR=$(mktemp -d)
      magick convert "$ICON_SRC" -resize 16x16 "$TMPDIR/icon-16.png"
      magick convert "$ICON_SRC" -resize 32x32 "$TMPDIR/icon-32.png"
      magick convert "$ICON_SRC" -resize 48x48 "$TMPDIR/icon-48.png"
      magick convert "$ICON_SRC" -resize 256x256 "$TMPDIR/icon-256.png"
      magick convert "$TMPDIR/icon-16.png" "$TMPDIR/icon-32.png" "$TMPDIR/icon-48.png" "$TMPDIR/icon-256.png" "$REPO_ROOT/windows/runner/resources/app_icon.ico"
      rm -rf "$TMPDIR"
    elif command -v convert >/dev/null 2>&1; then
      echo "Generating app_icon.ico from $ICON_SRC using convert"
      TMPDIR=$(mktemp -d)
      convert "$ICON_SRC" -resize 16x16 "$TMPDIR/icon-16.png"
      convert "$ICON_SRC" -resize 32x32 "$TMPDIR/icon-32.png"
      convert "$ICON_SRC" -resize 48x48 "$TMPDIR/icon-48.png"
      convert "$ICON_SRC" -resize 256x256 "$TMPDIR/icon-256.png"
      convert "$TMPDIR/icon-16.png" "$TMPDIR/icon-32.png" "$TMPDIR/icon-48.png" "$TMPDIR/icon-256.png" "$REPO_ROOT/windows/runner/resources/app_icon.ico"
      rm -rf "$TMPDIR"
    else
      echo "ImageMagick not found: skipping automatic generation of app_icon.ico. Install ImageMagick or provide an app_icon.ico in the source folder."
      # Try Python + Pillow fallback
      if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
        PY=$(command -v python || command -v python3)
        PHP_SCRIPT="$REPO_ROOT/scripts/png_to_ico.py"
        if [[ -f "$PHP_SCRIPT" ]]; then
          echo "Attempting to generate .ico using Python Pillow fallback"
          $PY "$PHP_SCRIPT" "$ICON_SRC" "$REPO_ROOT/windows/runner/resources/app_icon.ico" || echo "Python ICO generation failed"
        fi
      fi
    fi
  fi
fi

# Web: copy favicon if present
if [[ -f "$SRC_DIR/favicon.png" ]]; then
  echo "Copying favicon.png to web"
  cp -v "$SRC_DIR/favicon.png" "$REPO_ROOT/web/favicon.png"
elif [[ -f "$SRC_DIR/assets/icon/app_icon.png" ]]; then
  echo "Copying assets/icon/app_icon.png to web/favicon.png"
  cp -v "$SRC_DIR/assets/icon/app_icon.png" "$REPO_ROOT/web/favicon.png"
fi

echo "Icons installed. Run 'flutter pub run flutter_launcher_icons:main' if you also want to regenerate icons from assets/icon/app_icon.png."
