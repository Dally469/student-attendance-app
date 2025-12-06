#!/bin/bash
# Fix macOS Sandbox Error for Flutter Build

echo "🔧 Fixing macOS Sandbox Error..."
echo ""

PROJECT_DIR="/Users/rigobert/Documents/flutter/student-attendance-app"
cd "$PROJECT_DIR" || exit 1

echo "Step 1: Removing extended attributes from build directory..."
xattr -rc build/ 2>/dev/null
echo "✅ Extended attributes removed"
echo ""

echo "Step 2: Fixing build directory permissions..."
chmod -R 755 build/ 2>/dev/null
echo "✅ Permissions updated"
echo ""

echo "Step 3: Removing problematic build directories..."
rm -rf build/ios/Release-iphoneos
rm -rf build/ios/Debug-iphonesimulator
echo "✅ Build directories cleaned"
echo ""

echo "Step 4: Checking file ownership..."
OWNER=$(stat -f "%Su" build/ 2>/dev/null || echo "$USER")
echo "Build directory owner: $OWNER"
echo ""

if [ "$OWNER" != "$USER" ]; then
    echo "⚠️  Ownership issue detected. You may need to run:"
    echo "   sudo chown -R $(whoami) build/"
    echo ""
fi

echo "✅ Sandbox error fix applied!"
echo ""
echo "📱 Next steps:"
echo "1. Try building again: flutter build ios --simulator"
echo "2. Or build from Xcode: open ios/Runner.xcworkspace"
echo ""
echo "💡 If error persists, build from Xcode (it usually bypasses sandbox restrictions)"


