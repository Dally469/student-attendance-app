#!/bin/bash
# Create proper pod wrapper for RVM Ruby

echo "🔧 Creating pod wrapper for RVM Ruby..."
echo ""

# Remove existing pod wrapper
if [ -f /usr/local/bin/pod ]; then
    echo "Backing up existing pod..."
    sudo mv /usr/local/bin/pod /usr/local/bin/pod.backup.$(date +%Y%m%d_%H%M%S)
fi

# Create new wrapper
echo "Creating new wrapper script..."
sudo bash -c 'cat > /usr/local/bin/pod << "EOFWRAPPER"
#!/bin/bash
# CocoaPods wrapper that ensures RVM Ruby is used

# Set up RVM paths
export PATH="$HOME/.rvm/rubies/ruby-3.3.4/bin:$HOME/.rvm/bin:$PATH"

# Source RVM if available
if [ -s "$HOME/.rvm/scripts/rvm" ]; then
    source "$HOME/.rvm/scripts/rvm"
fi

# Use RVM Ruby's pod directly
exec "$HOME/.rvm/rubies/ruby-3.3.4/bin/pod" "$@"
EOFWRAPPER'

# Make executable
sudo chmod +x /usr/local/bin/pod

echo ""
echo "✅ Wrapper created!"
echo ""
echo "Testing..."
pod --version

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Pod is working correctly."
    echo ""
    echo "📱 Next steps:"
    echo "1. Restart your IDE completely (quit and reopen)"
    echo "2. Try running your Flutter app again"
    echo "3. It should work now! 🎉"
else
    echo ""
    echo "⚠️  Something might be wrong. Let's verify:"
    which pod
    cat /usr/local/bin/pod | head -5
fi






