#!/bin/bash
# Fix CocoaPods Ruby Version Mismatch

echo "🔧 Fixing CocoaPods Ruby Version Issue..."
echo ""

# Check current Ruby versions
echo "Current Ruby versions:"
echo "  RVM Ruby: $(~/.rvm/rubies/ruby-3.3.4/bin/ruby --version 2>/dev/null || echo 'Not found')"
echo "  System Ruby: $(/usr/bin/ruby --version 2>/dev/null || echo 'Not found')"
echo ""

# Solution 1: Install CocoaPods for system Ruby (Recommended)
echo "📦 Installing CocoaPods for system Ruby..."
sudo gem install cocoapods

if [ $? -eq 0 ]; then
    echo "✅ CocoaPods installed for system Ruby"
    echo ""
    echo "Verifying installation:"
    /usr/bin/ruby -S pod --version
    echo ""
    echo "✅ Done! Try running your Flutter app again."
else
    echo "❌ Installation failed. Trying alternative solution..."
    echo ""
    
    # Solution 2: Create wrapper script
    echo "📝 Creating pod wrapper script..."
    cat > /usr/local/bin/pod << 'EOF'
#!/bin/bash
export PATH="$HOME/.rvm/rubies/ruby-3.3.4/bin:$HOME/.rvm/bin:$PATH"
exec "$HOME/.rvm/rubies/ruby-3.3.4/bin/pod" "$@"
EOF
    
    chmod +x /usr/local/bin/pod
    echo "✅ Wrapper script created"
    echo ""
    echo "Verifying:"
    pod --version
fi

echo ""
echo "🎉 Setup complete! Restart your IDE and try running the app again."




