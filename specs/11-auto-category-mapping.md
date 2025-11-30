# 11 - Automatic Package Category Mapping & Ham Capability

## Status

Implemented (all hosts migrated)

## Overview

Introduces an automatic package category derivation system that converts structured `hostCapabilities` into a curated
list of package categories. Adds a new capability flag `features.ham` and corresponding `ham` package category.

## Goals

- Eliminate manual duplication of category lists across hosts.
- Provide deterministic, explainable category selection with provenance.
- Allow gradual adoption (opt-in per host).
- Support explicit overrides (force/exclude) without losing traceability.
- Introduce cleanly gated `ham` capability instead of heuristic detection.

## Non-Goals

- ~~Full immediate migration of all hosts (staged rollout starting with `cirice`).~~ **COMPLETED**
- Enforcing warnings as hard errors (soft phase only).
- ~~Automated removal of deprecated categories on non-migrated hosts.~~ **NO LONGER APPLICABLE**

## Capability Extension

Added to `lib/capability-schema.nix`:

```
features.ham = {
  type = lib.types.bool;
  default = false;
  description = "Amateur (ham) radio tools";
};
```

When `true`, category `ham` is added by the auto mapper.

## Mapping Logic

Implemented in `packages/auto-category-mapping.nix`.

Order of derivation (stable, first occurrence wins):

1. Baseline: `core`
1. Features → `development`, `multimedia`, `gaming`, `productivity` (from desktop/corporate), `development` (ai), `ham`
   (ham)
1. Roles → adds combinations of `system`, `productivity`, `fonts`, `gaming`, `multimedia`, `security`, `vpn` (mobile)
1. Services → `k8s-clients` (development), `system` (homeAssistant, distributedBuilds)
1. Security → `security`, `vpn`
1. Hardware/Display → `fonts`
1. Virtualization → `system` (windowsGpuPassthrough)

After derivation:

- Apply `options.exclude` filter early.
- Append `explicit` and `options.force` lists.
- Stable uniqueness preserving first appearance.

## Warnings (Soft)

Current warnings (non-fatal):

- `gaming` active but capability disabled.
- `vpn` active but `security.vpn = false`.
- `k8s-clients` active without `development` feature.

Warnings returned via `deriveCategories.warnings`; hosts may surface them (`lib.warn`) if desired.

## Overrides

`deriveCategories { explicit = [ ... ]; options = { enable = true; exclude = [ ... ]; force = [ ... ]; }; }`

- `explicit`: Legacy/manual additions (still traced).
- `exclude`: Remove derived categories before merge.
- `force`: Always append (even if conditions unmet; may suppress warnings if feature intentionally omitted).
- `enable = false`: Disables auto logic, returning only `core` + explicit + force.

## Ham Category

File: `packages/categories/ham.nix`

- Initially minimal (scaffold) but activated only when `features.ham = true` or explicitly forced.
- Not auto-inferred from other heuristics to avoid surprise tool installation.

## Rollout Strategy

~~Phase 1 (complete): Implement + enable on `cirice` only.~~ ~~Phase 2 (optional): Migrate additional hosts after
validating output parity.~~ Phase 3 (optional): Add CI flag to escalate warnings to errors.

**COMPLETED**: All hosts migrated to auto-category mapping:

- `cirice` (NixOS laptop)
- `nixair` (NixOS laptop)
- `dracula` (NixOS laptop)
- `legion` (NixOS workstation)
- `SGRIMEE-M-4HJT` (Darwin laptop)

## Testing

New test file: `tests/auto-category-mapping.nix` validates:

- Baseline inclusion (`core`, `development`).
- Ham inclusion only when feature set.
- Gaming warning when explicitly requested but feature disabled.
- VPN + K8s-clients conditional categories.

Integrated into suite via `tests/default.nix` (`systemTests`).

## Usage Example (all hosts)

```nix
auto = packageManager.deriveCategories {
  explicit = [ ];
  options = { enable = true; exclude = [ ]; force = [ ]; };
};
requestedCategories = auto.categories;
```

## Key Changes Made

- **K8s-Clients Independence**: K8s client tools now derive from `development` feature, not Docker dependency
- **Mobile VPN**: Mobile role automatically includes VPN category (Linux: NetworkManager tools, Darwin: empty)
- **Platform Compatibility**: All categories now handle cross-platform package selection
- **Ham Capability**: Available on all hosts when `features.ham = true`

## Future Enhancements (Optional)

- Add provenance-aware formatting tool to emit human-readable trace table.
- CI env var (e.g. `CI_ENFORCE_CATEGORY_WARNINGS=1`) to fail on warnings.
- Additional category families (observability, embedded, data-eng) keyed off future capabilities.
- Auto-suggest capability adjustments when warnings persist.

## Rationale

Centralizing category logic reduces drift and clarifies why a package set exists for a host. A conservative ham
capability flag prevents overreach while enabling targeted expansion for specialized tooling.

______________________________________________________________________

End of spec.
