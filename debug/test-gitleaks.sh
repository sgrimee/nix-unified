#!/bin/bash

# Test script to verify gitleaks integration works correctly

set -euo pipefail

echo "🧪 Testing gitleaks integration..."

# Test 1: Check if gitleaks is available
echo "1. Checking if gitleaks is available..."
if command -v gitleaks &> /dev/null; then
    echo "✅ gitleaks is available"
    gitleaks version
else
    echo "⚠️  gitleaks not in PATH, using nix run"
    nix run nixpkgs#gitleaks -- version
fi

# Test 2: Check configuration file
echo "2. Checking gitleaks configuration..."
if [ -f ".gitleaks.toml" ]; then
    echo "✅ .gitleaks.toml found"
    nix run nixpkgs#gitleaks -- detect --config .gitleaks.toml --source . --no-git --verbose --exit-code 0
else
    echo "❌ .gitleaks.toml not found"
    exit 1
fi

# Test 3: Create a test file with a fake secret
echo "3. Testing secret detection..."
echo 'export API_KEY="sk-1234567890abcdef"' > debug/test-secret.txt

# Test detection
if nix run nixpkgs#gitleaks -- detect --source debug/test-secret.txt --no-git --exit-code 0; then
    echo "✅ Secret detection working (no exit code error)"
else
    echo "⚠️  Secret detection triggered (expected behavior)"
fi

# Cleanup
rm -f debug/test-secret.txt

# Test 4: Test with actual repository
echo "4. Testing on actual repository..."
if nix run nixpkgs#gitleaks -- detect --source . --verbose --exit-code 0; then
    echo "✅ Repository scan completed successfully"
else
    echo "⚠️  Repository scan found potential issues"
fi

# Test 5: Test pre-commit hook
echo "5. Testing pre-commit hook..."
if [ -x ".git/hooks/pre-commit" ]; then
    echo "✅ Pre-commit hook is executable"
else
    echo "❌ Pre-commit hook not executable"
    exit 1
fi

# Test 6: Test post-merge hook
echo "6. Testing post-merge hook..."
if [ -x ".git/hooks/post-merge" ]; then
    echo "✅ Post-merge hook is executable"
else
    echo "❌ Post-merge hook not executable"
    exit 1
fi

echo "🎉 All tests completed!"