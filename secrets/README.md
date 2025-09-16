# Secrets Management

This directory contains encrypted secrets managed with [SOPS](https://github.com/getsops/sops).

## Structure

```
secrets/
├── shared/
│   └── sgrimee.yaml      # Shared secrets (accessible by all hosts)
├── nixair/               # Host-specific secrets for nixair
├── cirice/               # Host-specific secrets for cirice
├── dracula/              # Host-specific secrets for dracula
├── legion/               # Host-specific secrets for legion
├── mbp_16_2023/          # Host-specific secrets for mbp_16_2023
└── README.md             # This file
```

## Access Control

Secrets are encrypted using Age keys. Access is controlled by `.sops.yaml`:

- **Host-specific secrets**: Only accessible by the specific host and admin
- **Shared secrets**: Accessible by all configured hosts
- **Legacy secrets**: Root-level secrets maintain backward compatibility

## Common Commands

### Edit Secrets

```bash
# Edit shared secrets (all hosts can access)
just secret-edit

# Edit host-specific secrets
just secret-edit-host nixair
just secret-edit-host cirice
```

### Validate Secrets

```bash
# Check all secret files can be decrypted
just secret-validate

# List all available secrets
just secret-list
```

## Integration

Secrets are integrated into NixOS/Darwin configurations via the `sops-nix` module. See `modules/nixos/sops.nix` for configuration.

Example usage in configuration:
```nix
sops.secrets."service/api-key" = {
  sopsFile = ../../secrets/shared/services.yaml;
  owner = "service-user";
};
```

## Best Practices

1. **Use host-specific secrets** for sensitive data that should only be accessible by one host
2. **Use shared secrets** for configuration that multiple hosts need
3. **Never commit unencrypted secrets** to git
4. **Validate secrets** before committing changes
5. **Use descriptive secret names** following the pattern `category/name`

## Secret Categories

- **Network**: WiFi passwords, VPN credentials
- **Services**: API keys, service credentials
- **Personal**: Account credentials, tokens
- **System**: Admin passwords, SSH keys

## Troubleshooting

If you cannot decrypt secrets:
1. Ensure your Age key is in the `.sops.yaml` file
2. Check that the secret file exists and is properly encrypted
3. Verify you have the correct permissions
4. Run `just validate-secrets` to check all files

For more information, see the [SOPS documentation](https://github.com/getsops/sops).