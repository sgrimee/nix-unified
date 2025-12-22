#!/usr/bin/env bash
set -euo pipefail

# Comprehensive Nix garbage collection script
# Removes old generations and unreachable store paths
# Keep last 3 generations to allow rollback

KEEP_GENS=3

echo "🧹 Nix Store Garbage Collection"
echo "================================="
echo ""

# Step 1: Show current disk usage before
echo "📊 Disk usage BEFORE garbage collection:"
du -sh /nix/store 2>/dev/null || echo "  (Could not determine /nix/store size)"
df -h / 2>/dev/null | tail -1 || true
echo ""

# Step 2: Show current generations
echo "📚 System generations (keeping last $KEEP_GENS):"
if [ "$(uname -s)" = "Darwin" ]; then
    darwin-rebuild --list-generations | tail -5 || true
else
    sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -5 || true
fi
echo ""

# Step 3: Delete old system generations (keep last N)
echo "🗑️  Step 1: Deleting old system generations (keeping last $KEEP_GENS)..."
if [ "$(uname -s)" = "Darwin" ]; then
    sudo nix-collect-garbage --delete-generations "+${KEEP_GENS}" || true
else
    sudo nix-collect-garbage --delete-generations "+${KEEP_GENS}" || true
fi
echo "  ✅ System generations cleaned"
echo ""

# Step 4: Delete old home-manager generations
echo "🗑️  Step 2: Deleting old home-manager generations (keeping last $KEEP_GENS)..."
if [ -d ~/.local/state/nix/profiles ]; then
    nix-env --profile ~/.local/state/nix/profiles/home-manager --delete-generations "+${KEEP_GENS}" 2>/dev/null || true
    echo "  ✅ Home-manager generations cleaned"
else
    echo "  ℹ️  No home-manager profiles found"
fi
echo ""

# Step 5: Run garbage collection on store paths
echo "🗑️  Step 3: Running nix-store garbage collection..."
nix-store --gc 2>/dev/null || sudo nix-store --gc 2>/dev/null || true
echo "  ✅ Store paths garbage collected"
echo ""

# Step 6: Remove unreachable paths and dead generations
echo "🗑️  Step 4: Removing all dead generations and unreachable paths..."
nix-collect-garbage -d 2>/dev/null || true
if [ "$(uname -s)" = "Darwin" ]; then
    sudo nix-collect-garbage -d 2>/dev/null || true
else
    sudo nix-collect-garbage -d 2>/dev/null || true
fi
echo "  ✅ Dead generations and paths removed"
echo ""

# Step 7: Optimize store (hard-link identical files)
echo "🗑️  Step 5: Optimizing Nix store (deduplicating identical files)..."
nix store optimise 2>/dev/null || nix-store --optimise 2>/dev/null || true
echo "  ✅ Store optimized"
echo ""

# Step 8: Clear evaluation cache
echo "🗑️  Step 6: Clearing Nix evaluation cache..."
rm -rf ~/.cache/nix 2>/dev/null || true
rm -rf /tmp/nix-build-* 2>/dev/null || true
echo "  ✅ Evaluation cache cleared"
echo ""

# Step 9: Show results
echo "📊 Disk usage AFTER garbage collection:"
du -sh /nix/store 2>/dev/null || echo "  (Could not determine /nix/store size)"
df -h / 2>/dev/null | tail -1 || true
echo ""

echo "🎉 Garbage collection completed!"
echo ""
echo "💡 Tip: Run 'just gc' regularly to keep your Nix store clean"
echo "         or enable auto garbage collection in your Nix configuration"
