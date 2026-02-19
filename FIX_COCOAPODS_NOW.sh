#!/bin/bash
# Quick Fix for CocoaPods "broken" error

echo "🔧 Fixing CocoaPods Ruby Version Issue..."
echo ""

# Check current setup
echo "Current CocoaPods locations:"
which -a pod
echo ""

# Solution: Install CocoaPods for system Ruby
echo "📦 Installing CocoaPods for system Ruby (so Flutter can use it)..."
echo "This requires your password..."
echo ""

sudo /usr/bin/gem install cocoapods

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! CocoaPods installed for system Ruby"
    echo ""
    echo "Verifying installation:"
    /usr/bin/ruby -S pod --version 2>/dev/null || pod --version
    echo ""
    echo "🎉 Done! Now:"
    echo "1. Restart your IDE completely"
    echo "2. Try running your Flutter app again"
    echo "3. It should work!"
else
    echo ""
    echo "❌ Installation failed or was cancelled."
    echo ""
    echo "Alternative: Try running this manually:"
    echo "  sudo gem install cocoapods"
fi








