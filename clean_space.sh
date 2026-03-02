#!/bin/bash
# clean_space.sh - Free disk space for Flutter/Android/iOS development
# Run from project root: ./clean_space.sh

set -e
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

echo "=== Cleaning space (project: $PROJECT_ROOT) ==="

# 1. Flutter project build output
if [ -d "build" ]; then
  echo "Removing build/ ..."
  rm -rf build
  echo "  Done."
fi

# 2. Dart/Flutter tool cache (regenerated on next flutter pub get)
if [ -d ".dart_tool" ]; then
  echo "Removing .dart_tool/ ..."
  rm -rf .dart_tool
  echo "  Done."
fi

# 3. Android Gradle in project
if [ -d "android/.gradle" ]; then
  echo "Removing android/.gradle/ ..."
  rm -rf android/.gradle
  echo "  Done."
fi

# 4. Android build output in project
if [ -d "android/app/build" ]; then
  echo "Removing android/app/build/ ..."
  rm -rf android/app/build
  echo "  Done."
fi

# 5. iOS build in project
if [ -d "ios/build" ]; then
  echo "Removing ios/build/ ..."
  rm -rf ios/build
  echo "  Done."
fi

# 6. Global Gradle caches (safe to clear; will re-download on next build)
GRADLE_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"
if [ -d "$GRADLE_HOME/caches" ]; then
  echo "Removing Gradle caches ($GRADLE_HOME/caches) ..."
  rm -rf "$GRADLE_HOME/caches"
  echo "  Done."
fi

# 7. Flutter clean (cleans build and regenerates as needed)
echo "Running flutter clean ..."
flutter clean 2>/dev/null || true
echo "  Done."

echo ""
echo "=== Cleanup finished ==="
echo "Run: flutter pub get"
echo "Then try your build again (e.g. flutter run)."
