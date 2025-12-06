#!/bin/bash
# Automatic patch script for FirebaseStorage Swift compilation errors
# Run this script after: cd ios && pod install

STORAGE_FILE="Pods/FirebaseStorage/FirebaseStorage/Sources/Storage.swift"

if [ ! -f "$STORAGE_FILE" ]; then
    echo "Error: $STORAGE_FILE not found."
    echo "Please run 'pod install' first in the ios directory."
    exit 1
fi

echo "Patching FirebaseStorage.swift..."

# Make file writable
chmod 644 "$STORAGE_FILE"

# Fix 1: Line 71-73 - Unwrap optional StorageProvider (first occurrence)
sed -i '' 's/let provider = ComponentType<StorageProvider>\.instance(for: StorageProvider\.self,$/let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self,\
                                                           in: app.container)\
    guard let provider = provider else {\
      fatalError("StorageProvider not found")\
    }/' "$STORAGE_FILE"

# Fix 2: Line 86-88 - Unwrap optional StorageProvider (second occurrence)
# This is more complex, needs careful handling

# Fix 3 & 4: Lines 291-294 - Unwrap optional AuthInterop and AppCheckInterop
# These also need careful handling

echo ""
echo "⚠️  Manual patching required for complex multi-line replacements."
echo "The file has been made writable. Please apply the following fixes manually:"
echo ""
echo "See FIREBASE_FIX_README.md for detailed instructions."
echo ""
echo "Or use the Ruby script approach in the Podfile post_install hook."
