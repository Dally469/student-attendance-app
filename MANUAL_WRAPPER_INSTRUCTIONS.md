# Manual Pod Wrapper Installation

## Current Status

✅ CocoaPods is working perfectly from command line  
✅ Pod install works successfully  
✅ All pods are installed  

The issue is that Flutter/IDE needs to be able to find CocoaPods. Since the wrapper script requires sudo (password), here's how to do it manually:

## Manual Installation Steps

### Step 1: Open Terminal

Open Terminal and navigate to your project:
```bash
cd /Users/rigobert/Documents/flutter/student-attendance-app
```

### Step 2: Create the Wrapper (requires password)

Run these commands one by one (you'll need to enter your password for sudo):

```bash
# Backup existing pod
sudo mv /usr/local/bin/pod /usr/local/bin/pod.backup

# Create new wrapper
sudo tee /usr/local/bin/pod > /dev/null << 'EOF'
#!/bin/bash
export PATH="$HOME/.rvm/rubies/ruby-3.3.4/bin:$HOME/.rvm/bin:$PATH"
if [ -s "$HOME/.rvm/scripts/rvm" ]; then
    source "$HOME/.rvm/scripts/rvm"
fi
exec "$HOME/.rvm/rubies/ruby-3.3.4/bin/pod" "$@"
EOF

# Make it executable
sudo chmod +x /usr/local/bin/pod
```

### Step 3: Verify It Works

```bash
which pod
pod --version
```

Should show: `1.16.2`

### Step 4: Restart IDE

1. **Quit your IDE completely** (Cursor/VS Code/Android Studio)
2. Reopen it
3. Try running your Flutter app again

## Alternative: Configure IDE to Use RVM Ruby

If you prefer not to use sudo, you can configure your IDE to use RVM Ruby:

### For VS Code / Cursor:

1. Open Settings (Cmd+,)
2. Search for "terminal integrated shell path" or "terminal env"
3. Add this to your IDE's terminal environment or `~/.zshrc`:

```bash
export PATH="$HOME/.rvm/rubies/ruby-3.3.4/bin:$HOME/.rvm/bin:$PATH"
```

4. Restart your IDE

### Check Your Shell Profile

Add RVM to your PATH permanently:

```bash
# Add to ~/.zshrc
echo 'export PATH="$HOME/.rvm/rubies/ruby-3.3.4/bin:$HOME/.rvm/bin:$PATH"' >> ~/.zshrc

# Reload
source ~/.zshrc
```

Then restart your IDE.

## Current Status

✅ CocoaPods working (RVM Ruby 3.3.4)  
✅ Pods installed  
✅ All code errors fixed  
✅ Pod install works from command line  

⚠️ Just need to ensure Flutter/IDE can find it

## Why This Is Needed

Flutter's IDE integration runs CocoaPods checks in an environment that might not have RVM in PATH. The wrapper ensures CocoaPods is always found, regardless of the environment.

## Quick Test

After creating the wrapper, test it:

```bash
# Should work from anywhere
cd ~
pod --version

cd /Users/rigobert/Documents/flutter/student-attendance-app/ios
pod install
```

Both should work without errors!






