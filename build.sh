#!/bin/bash
# =============================================================================
# Ibex Classroom — Flutter Web Build Script for Vercel
# =============================================================================
# This script is executed by Vercel during the build phase.
# It downloads (or reuses cached) Flutter, then builds the web app.
# =============================================================================

set -e  # Exit immediately on error

FLUTTER_VERSION="3.41.4"
FLUTTER_CHANNEL="stable"
FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/${FLUTTER_ARCHIVE}"
FLUTTER_DIR="$(pwd)/flutter"

echo "=============================="
echo "  Ibex Classroom — Web Build"
echo "  Flutter ${FLUTTER_VERSION}"
echo "=============================="

# ── Install Flutter (skip if already cached) ──────────────────────────────────
if [ ! -d "$FLUTTER_DIR" ] || [ ! -f "$FLUTTER_DIR/bin/flutter" ]; then
  echo "📦 Downloading Flutter ${FLUTTER_VERSION}..."
  curl -fsSL "$FLUTTER_URL" | tar xJ
  echo "✅ Flutter downloaded."
else
  echo "✅ Flutter already available at $FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

# Required for git operations in Vercel's container  
git config --global --add safe.directory "$FLUTTER_DIR"

echo ""
echo "📋 Flutter version:"
flutter --version

echo ""
echo "📦 Fetching dependencies..."
flutter pub get

echo ""
echo "🔍 Analyzing code..."
flutter analyze --no-fatal-infos || echo "⚠️  Analysis warnings found (non-fatal)"

echo ""
echo "🏗️  Building Flutter Web (release mode)..."
flutter build web \
  --release \
  --pwa-strategy=offline-first \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
  --no-source-maps \
  --base-href "/"

echo ""
echo "✅ Build complete! Output: build/web/"
echo ""

# ── Post-build: list output for verification ──────────────────────────────────
echo "📁 Build output:"
ls -lh build/web/ 2>/dev/null || echo "Build directory not found"
