#!/bin/bash
# Fix pod wrapper to work with RVM Ruby

echo "🔧 Creating proper pod wrapper for RVM Ruby..."
echo ""

# Backup existing pod if it exists
if [ -f /usr/local/bin/pod ] && [ ! -L /usr/local/bin/pod ]; then
    echo "Backing up existing pod to /usr/local/bin/pod.backup"
    sudo mv /usr/local/bin/pod /usr/local/bin/pod.backup
fi

# Create proper wrapper script
echo "Creating wrapper script..."
sudo tee /usr/local/bin/pod > /dev/null << 'EOF'
#!/bin/bash
# CocoaPods wrapper that uses RVM Ruby

# Load RVM
export PATH="$HOME/.rvm/rubies/ruby-3.3.4/bin:$HOME/.rvm/bin:$PATH"

# Source RVM if it exists
if [ -s "$HOME/.rvm/scripts/rvm" ]; then
    source "$HOME/.rvm/scripts/rvm"
fi

# Use RVM Ruby's pod
exec "$HOME/.rvm/rubies/ruby-3.3.4/bin/pod" "$@"
EOF

# Make it executable
sudo chmod +x /usr/local/bin/pod

echo "✅ Wrapper script created!"
echo ""
echo "Testing..."
pod --version

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Pod wrapper is working."
    echo ""
    echo "Now:"
    echo "1. Restart your IDE completely"
    echo "2. Try running your Flutter app again"
    echo "3. It should work!"
else
    echo ""
    echo "❌ Something went wrong. Let's check:"
    which pod
    pod --version
fi







