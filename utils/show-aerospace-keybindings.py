#!/usr/bin/env python3

import subprocess
import json
import os
import re

def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except Exception as e:
        return False, '', str(e)

def parse_aerospace_config(config_path):
    """Parse Aerospace TOML config and extract keybindings"""
    bindings = {}

    try:
        # Try to use yq if available for better TOML parsing
        if run_cmd('command -v yq')[0]:
            success, output, _ = run_cmd(f'yq -o=json \'{config_path}\'')
            if success:
                config = json.loads(output)
                mode_main = config.get('mode', {}).get('main', {}).get('binding', {})

                for key, action in mode_main.items():
                    # Clean up the key format
                    clean_key = key.replace('key.', '').replace('mod.', '')
                    bindings[clean_key] = str(action)
                return bindings
    except Exception:
        pass

    # Fallback: parse raw TOML sections
    try:
        with open(config_path, 'r') as f:
            content = f.read()

        # Find the [mode.main.binding] section
        binding_section = re.search(r'\[mode\.main\.binding\](.*?)(?=\n\[|\Z)', content, re.DOTALL)
        if binding_section:
            section = binding_section.group(1)
            # Parse key = value lines
            for line in section.split('\n'):
                line = line.strip()
                if '=' in line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"\'')
                    bindings[key] = value

    except Exception as e:
        print(f"⚠️  Error parsing config: {e}")

    return bindings

def main():
    print("🚀 Aerospace Keybindings Analysis")
    print("==================================")

    # Check if Aerospace config exists
    aerospace_config = os.path.expanduser("~/.aerospace.toml")
    if not os.path.isfile(aerospace_config):
        print(f"❌ Aerospace configuration not found at {aerospace_config}")
        print("💡 Note: Aerospace configuration is typically managed through home-manager")
        return

    print(f"✅ Found Aerospace configuration at {aerospace_config}")

    # Parse the configuration
    bindings = parse_aerospace_config(aerospace_config)

    if not bindings:
        print("❌ Could not parse any keybindings from the configuration")
        return

    print(f"📋 Found {len(bindings)} keybindings")

    # Group bindings by action type
    action_map = {}

    # Common Aerospace actions (these would be "defaults" if we had them)
    # For now, we'll just show all actions as "live" since we don't have a comprehensive defaults database
    for key, action in bindings.items():
        if action not in action_map:
            action_map[action] = {
                'keys': [],
                'status': 'live'  # All bindings are from live config
            }
        action_map[action]['keys'].append(key)

    # Categorize actions
    categories = {
        'window_management': [],
        'workspace': [],
        'mode': [],
        'other': []
    }

    for action, info in action_map.items():
        if any(keyword in action.lower() for keyword in ['focus', 'move', 'resize', 'close', 'fullscreen', 'float']):
            categories['window_management'].append((action, info))
        elif any(keyword in action.lower() for keyword in ['workspace']):
            categories['workspace'].append((action, info))
        elif any(keyword in action.lower() for keyword in ['mode']):
            categories['mode'].append((action, info))
        else:
            categories['other'].append((action, info))

    # Display results
    for category, actions in categories.items():
        if not actions:
            continue

        category_name = category.replace('_', ' ').title()
        print(f"\n  {category_name}:")
        for action, info in sorted(actions, key=lambda x: x[0]):
            keys_str = ', '.join(sorted(info['keys']))
            print(f"    📋 {action:<35} | Keys: {keys_str}")

    print("\nLegend: 📋 = live keybinding from Aerospace configuration")
    print(f"Total: {len(bindings)} keybindings across {len([a for actions in categories.values() for a in actions])} actions")

if __name__ == '__main__':
    main()