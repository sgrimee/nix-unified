# Spec 19: Configuration Cleanup and Refactoring

## Status
🚧 In Progress - Phase 1 Complete

## Context
Based on comprehensive analysis of the nix configuration, multiple areas have been identified for improvement in organization, clarity, and maintainability. This spec consolidates all recommendations into actionable steps.

### Key Decisions
- **Auto-categories**: Removing auto-category derivation system (not needed)
- **Capability system**: Required for ALL hosts (no traditional mode)
- **Reporting/graphing**: Removing unused reporting and graph export system

## Goals
1. Reduce abstraction layers and complexity
2. Improve code organization and discoverability
3. Enhance documentation clarity
4. Remove unused/over-engineered features
5. Standardize naming and conventions

## Implementation Steps

### Phase 1: Quick Wins (Immediate)
✅ **Step 1.1**: Add table of contents to CLAUDE.md
- Add TOC at top of file
- Group related commands with clear headers
- Estimated time: 10 minutes

✅ **Step 1.2**: Extract hardcoded user to constant
- Move `user = "sgrimee"` from capability-loader.nix to shared config
- Add user to capability schema as configurable option
- Estimated time: 5 minutes

✅ **Step 1.3**: Standardize parameter names
- Use consistent `hostCapabilities` everywhere (not `capabilities`)
- Use consistent `requestedCategories` (not `categories`)
- Estimated time: 30 minutes

✅ **Step 1.4**: Add inline comments to complex functions
- Document capability-loader.nix lines 44-76 (module generation)
- Add explanation of module separation (system vs home-manager)
- Estimated time: 15 minutes

✅ **Step 1.5**: Document auto-category-mapping usage
- Add comment explaining provenance trace output
- Document when/why to use auto-derivation
- Estimated time: 10 minutes

**Total Phase 1 time**: ~70 minutes

### Phase 2: Remove Auto-Category System (High Priority)
⏳ **Step 2.1**: Remove auto-category-mapping.nix
- Delete `packages/auto-category-mapping.nix`
- Remove from package manager exports
- Estimated time: 10 minutes

⏳ **Step 2.2**: Update all host packages.nix to explicit categories
- Convert all hosts to use explicit `requestedCategories` lists
- Remove `auto` derivation calls
- Update cirice, dracula, legion, nixair, SGRIMEE-M-4HJT
- Estimated time: 30 minutes

⏳ **Step 2.3**: Simplify package manager
- Remove `deriveCategories` and `autoGenerateCategories` functions
- Simplify manager.nix interface
- Update documentation
- Estimated time: 20 minutes

⏳ **Step 2.4**: Update tests
- Remove auto-category mapping tests
- Update package management tests for explicit-only mode
- Estimated time: 15 minutes

**Total Phase 2 time**: ~75 minutes

### Phase 3: Remove Reporting/Graphing System (High Priority)
⏳ **Step 3.1**: Remove reporting infrastructure from flake.nix
- Remove `hostPackageMapping` output (lines 162-262)
- Remove reporting imports and functions
- Estimated time: 15 minutes

⏳ **Step 3.2**: Delete reporting library
- Remove `lib/reporting/` directory
- Update lib structure documentation
- Estimated time: 5 minutes

⏳ **Step 3.3**: Clean up related test files
- Remove or update tests that depend on reporting
- Estimated time: 10 minutes

⏳ **Step 3.4**: Remove justfile reporting commands
- Remove package mapping visualization commands
- Update justfile documentation
- Estimated time: 5 minutes

**Total Phase 3 time**: ~35 minutes

### Phase 4: Consolidate Capability System (Medium Priority)
⏳ **Step 4.1**: Merge capability-integration.nix into capability-loader.nix
- Combine tightly coupled files
- Rename to `capability-system.nix`
- Update imports in flake.nix
- Estimated time: 45 minutes

⏳ **Step 4.2**: Merge dependency-resolver.nix into capability-system.nix
- Move dependency resolution into main capability system
- Only used in one place, no need for separation
- Estimated time: 30 minutes

⏳ **Step 4.3**: Remove traditional/backwards compatibility mode
- Remove fallback to traditional imports in capability-integration
- Require capabilities.nix for all hosts
- All hosts already have capabilities.nix, so safe to remove
- Estimated time: 20 minutes

⏳ **Step 4.4**: Update documentation
- Document new simplified capability system structure
- Update CLAUDE.md with new file organization
- Estimated time: 15 minutes

**Total Phase 4 time**: ~110 minutes

### Phase 5: Split Module Mapping (Medium Priority)
⏳ **Step 5.1**: Create lib/module-mapping/ directory structure
- Create subdirectories for each category
- Estimated time: 5 minutes

⏳ **Step 5.2**: Split module-mapping.nix into category files
- Create core.nix, features.nix, hardware.nix, roles.nix, environment.nix, services.nix, security.nix, virtualization.nix
- Move relevant sections to each file
- Estimated time: 60 minutes

⏳ **Step 5.3**: Create module-mapping/default.nix aggregator
- Combine all category files
- Maintain same export structure
- Estimated time: 15 minutes

⏳ **Step 5.4**: Update imports
- Update capability-system.nix to import from new location
- Test that all hosts still build
- Estimated time: 15 minutes

**Total Phase 5 time**: ~95 minutes

### Phase 6: Reduce flake.nix Size (Medium Priority)
⏳ **Step 6.1**: Extract host discovery to lib/host-discovery.nix
- Move `discoverHosts` and related functions
- Import in flake.nix
- Estimated time: 30 minutes

⏳ **Step 6.2**: Extract test checks to tests/checks.nix
- Move all inline test definitions from flake.nix
- Keep flake.nix with simple import
- Estimated time: 45 minutes

⏳ **Step 6.3**: Simplify flake outputs
- Remove redundant outputs
- Clean up output organization
- Estimated time: 20 minutes

⏳ **Step 6.4**: Verify flake.nix is under 200 lines
- Review and consolidate remaining code
- Estimated time: 15 minutes

**Total Phase 6 time**: ~110 minutes

### Phase 7: Improve Documentation (Low Priority)
⏳ **Step 7.1**: Restructure CLAUDE.md
- Add Quick Start section at top
- Move detailed explanations to docs/ directory
- Keep CLAUDE.md focused on common operations
- Estimated time: 45 minutes

⏳ **Step 7.2**: Create docs/architecture.md
- Document capability system design
- Explain module mapping approach
- Include decision rationale
- Estimated time: 30 minutes

⏳ **Step 7.3**: Create docs/package-management.md
- Document package category system
- Explain how to add packages
- Provide examples
- Estimated time: 30 minutes

⏳ **Step 7.4**: Update README.md
- Ensure README reflects current structure
- Add links to new documentation
- Estimated time: 15 minutes

**Total Phase 7 time**: ~120 minutes

### Phase 8: Standardization and Cleanup (Low Priority)
⏳ **Step 8.1**: Standardize platform naming
- Use "darwin" in code, "macOS" in docs/comments
- Update capability schema comments
- Find/replace inconsistencies
- Estimated time: 30 minutes

⏳ **Step 8.2**: Simplify justfile test commands
- Consolidate test commands with arguments
- `just test [--verbose] [--platform=PLATFORM]`
- Keep specialized commands separate
- Estimated time: 45 minutes

⏳ **Step 8.3**: Add capability schema validation enforcement
- Add assertions in capability-system to validate on import
- Document validation behavior
- Estimated time: 30 minutes

⏳ **Step 8.4**: Reduce Home Manager module injection complexity
- Simplify module passing through sharedModules
- Make home-manager modules first-class output
- Estimated time: 45 minutes

**Total Phase 8 time**: ~150 minutes

## Implementation Summary

### Time Estimates
- **Phase 1 (Quick Wins)**: ~70 minutes - ✅ **COMPLETED**
- **Phase 2 (Remove Auto-Categories)**: ~75 minutes
- **Phase 3 (Remove Reporting)**: ~35 minutes
- **Phase 4 (Consolidate Capability System)**: ~110 minutes
- **Phase 5 (Split Module Mapping)**: ~95 minutes
- **Phase 6 (Reduce flake.nix)**: ~110 minutes
- **Phase 7 (Documentation)**: ~120 minutes
- **Phase 8 (Standardization)**: ~150 minutes

**Total estimated time**: ~765 minutes (~13 hours)

### Recommended Implementation Order
1. ✅ Phase 1: Quick wins for immediate improvement
2. Phase 2: Remove auto-categories (simplifies system)
3. Phase 3: Remove reporting (removes unused code)
4. Phase 4: Consolidate capability system (reduces complexity)
5. Phase 5: Split module mapping (improves organization)
6. Phase 6: Reduce flake.nix (improves maintainability)
7. Phase 7: Documentation (captures improvements)
8. Phase 8: Final polish and standardization

### Benefits After Completion
- **Reduced complexity**: 4-5 abstraction layers → 2-3 layers
- **Better organization**: Related code co-located
- **Clearer purpose**: Each file has single responsibility
- **Easier maintenance**: Smaller files, better documented
- **Faster onboarding**: Clearer structure and documentation
- **Removed unused code**: Auto-categories and reporting removed

## Testing Strategy
- Run `just check` after each phase
- Run `just test` for comprehensive validation
- Build all hosts to verify no breakage
- Review capability debug output for each host

## Rollback Plan
- Each phase should be committed separately
- Git revert available for each phase
- No breaking changes to host configurations until Phase 4.3

## Notes
- Auto-category system was clever but over-engineered for actual usage
- Reporting system was built but never actively used
- Capability system is valuable and should be mandatory for consistency
- User hardcoding should be fixed before adding more hosts

## Related Specs
- Spec 03: Module Categories Feature Flags (context for capability system)
- Spec 04: Centralized Package Management (package category system)
- Spec 09: Module Dependency Management (dependency resolver)
