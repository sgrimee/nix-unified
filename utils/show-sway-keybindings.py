#!/usr/bin/env python3

import subprocess
import json

def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except Exception as e:
        return False, '', str(e)

def normalize_key(key):
    # For comparison, we want to compare the binding action, not the key format
    # So we don't normalize Mod1/Mod4 here - we compare the actual key strings
    return key

def main():
    try:
        print("🔴 Sway Keybindings Analysis")
        print("============================")

        # Build default keybindings object
        defaults = {
            'window_management': {
                'Mod+h': {'action': 'focus left', 'default': True},
                'Mod+j': {'action': 'focus down', 'default': True},
                'Mod+k': {'action': 'focus up', 'default': True},
                'Mod+l': {'action': 'focus right', 'default': True},
                'Mod+Shift+h': {'action': 'move left', 'default': True},
                'Mod+Shift+j': {'action': 'move down', 'default': True},
                'Mod+Shift+k': {'action': 'move up', 'default': True},
                'Mod+Shift+l': {'action': 'move right', 'default': True},
                'Mod+space': {'action': 'focus mode_toggle', 'default': True},
                'Mod+Shift+space': {'action': 'floating toggle', 'default': True},
            },
            'layouts': {
                'Mod+s': {'action': 'layout stacking', 'default': True},
                'Mod+w': {'action': 'layout tabbed', 'default': True},
                'Mod+e': {'action': 'layout toggle split', 'default': True},
            },
            'applications': {
                'Mod+Return': {'action': 'exec foot (or configured terminal)', 'default': True},
            },
            'system': {
                'Mod+Shift+q': {'action': 'kill', 'default': True},
                'Mod+Shift+c': {'action': 'reload', 'default': True},
                'Mod+Shift+e': {'action': 'exec wlogout (or configured logout)', 'default': True},
                'Mod+Shift+r': {'action': 'mode resize', 'default': True},
            },
            'workspaces': {
                'Mod+1-10': {'action': 'workspace number 1-10', 'default': True},
                'Mod+Shift+1-10': {'action': 'move container to workspace 1-10', 'default': True},
            }
        }

        # Load live configuration
        live_bindings = {}
        success, config_output, _ = run_cmd('swaymsg -t get_config')
        if success:
            print("✅ Loaded live Sway configuration")
            config_data = json.loads(config_output)
            config_text = config_data.get('config', '')
            for line in config_text.split('\n'):
                if line.strip().startswith('bindsym'):
                    parts = line.strip().split()
                    if len(parts) >= 3:
                        key = parts[1].replace('$mod', 'Mod')
                        action = ' '.join(parts[2:])
                        live_bindings[normalize_key(key)] = action
        else:
            print("⚠️  Could not load live Sway configuration (is Sway running?)")
            print("   Showing defaults only...")
            live_bindings = {}

        # Get configured modifier from Nix
        modifier = 'Mod1'  # Default
        success, nix_output, _ = run_cmd('grep -A5 "modifier.*=" modules/home-manager/wl-sway.nix')
        if success:
            for line in nix_output.split('\n'):
                if '"' in line:
                    import re
                    match = re.search(r'"([^"]*)"', line.strip())
                    if match:
                        modifier = match.group(1)
                        break

        print(f"Modifier key: {modifier}")
        print()

        # Create action-based mapping
        action_map = {}

        # First, populate with defaults
        for category, bindings in defaults.items():
            for key, info in bindings.items():
                action = info['action']
                display_key = key.replace('Mod+', f'{modifier}+')
                if action not in action_map:
                    action_map[action] = {
                        'category': category,
                        'default_key': display_key,
                        'actual_key': display_key,
                        'status': 'default'
                    }

        # Then update with live bindings
        for live_key, live_action in live_bindings.items():
            display_live_key = live_key.replace('Mod+', f'{modifier}+')

            if live_action in action_map:
                # This action exists in defaults
                if action_map[live_action]['default_key'] != display_live_key:
                    # The key has changed
                    action_map[live_action]['actual_key'] = display_live_key
                    action_map[live_action]['status'] = 'remapped'
            else:
                # This is a custom action not in defaults
                action_map[live_action] = {
                    'category': 'custom',
                    'default_key': None,
                    'actual_key': display_live_key,
                    'status': 'custom'
                }

        # Display results organized by category
        categories = {}
        for action, info in action_map.items():
            cat = info['category']
            if cat not in categories:
                categories[cat] = []
            categories[cat].append((action, info))

        for category in sorted(categories.keys()):
            if category == 'custom':
                continue  # Handle custom separately

            category_name = category.replace('_', ' ').title()
            print(f'  {category_name}:')
            for action, info in sorted(categories[category], key=lambda x: x[0]):
                if info['status'] == 'remapped':
                    print(f'    🔄 {action:<35} | Default: {info["default_key"]:<12} | Actual: {info["actual_key"]}')
                else:
                    print(f'    📌 {action:<35} | Key: {info["actual_key"]}')
            print()

        # Show custom bindings
        if 'custom' in categories:
            print('  Custom Actions:')
            for action, info in sorted(categories['custom'], key=lambda x: x[0]):
                print(f'    ➕ {action:<35} | Key: {info["actual_key"]}')
            print()

        print('Legend: 📌 = default binding, 🔄 = remapped to different key, ➕ = custom action')

    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()