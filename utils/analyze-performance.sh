#!/bin/bash
set -e

echo "=== Nix Build Performance Analysis ==="
echo "System: $(uname -s) $(uname -m)"

# Check core count
if command -v nproc >/dev/null 2>&1; then
    cores=$(nproc)
elif command -v sysctl >/dev/null 2>&1; then
    cores=$(sysctl -n hw.ncpu)
else
    cores="unknown"
fi
echo "CPU Cores: $cores"

# Check memory
if command -v free >/dev/null 2>&1; then
    echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
elif command -v sysctl >/dev/null 2>&1; then
    # macOS memory detection
    mem_bytes=$(sysctl -n hw.memsize)
    mem_gb=$((mem_bytes / 1024 / 1024 / 1024))
    echo "Memory: ${mem_gb}GB"
else
    echo "Memory: unknown"
fi

echo ""
echo "=== Current Nix Settings ==="
nix config show | grep -E "(cores|jobs|substituters|cache|download)" | head -10
echo ""

echo "=== Store Statistics ==="
echo "Store path: $(nix eval --impure --expr 'builtins.storeDir')"
if command -v du >/dev/null 2>&1; then
    store_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
    echo "Store size: $store_size"
fi

echo ""
echo "=== Substituter Speed Test ==="
echo "Testing substituter connectivity..."
for sub in "https://cache.nixos.org/" "https://nix-community.cachix.org"; do
    if command -v curl >/dev/null 2>&1; then
        time_ms=$(curl -o /dev/null -s -w "%{time_total}" "$sub" 2>/dev/null || echo "failed")
        echo "$sub: ${time_ms}s"
    fi
done

echo ""
echo "=== Performance Recommendations ==="
current_jobs=$(nix config show | grep "max-jobs" | awk '{print $3}' || echo "1")
echo "Current max-jobs: $current_jobs"

# Check if our optimizations are active
current_subs=$(nix config show | grep "substituters =" | cut -d'=' -f2)
if [[ "$current_subs" != *"nix-community.cachix.org"* ]]; then
    echo "⚠️  Performance optimizations not active yet - run 'just switch' to apply"
fi

current_max_sub_jobs=$(nix config show | grep "max-substitution-jobs" | awk '{print $3}' || echo "1")
if [ "$current_max_sub_jobs" -lt "32" ]; then
    echo "⚠️  max-substitution-jobs is $current_max_sub_jobs (could be 32)"
fi

if [ "$current_jobs" != "auto" ] && [ "$current_jobs" -lt "$cores" ]; then
    echo "⚠️  Consider setting max-jobs = 'auto' for better parallelization"
fi

echo ""
echo "=== Recent Activity ==="
# Show recent generations
if [ -d "/nix/var/nix/profiles" ]; then
    echo "Recent generations:"
    ls -la /nix/var/nix/profiles/system* 2>/dev/null | tail -3 || echo "No system profiles found"
fi