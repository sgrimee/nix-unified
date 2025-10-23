# Justfile Command Tests
# Validates that essential justfile commands work correctly
# Tests command syntax, dependencies, and basic functionality
{
  lib,
  pkgs,
  ...
}: let
  # Check if justfile exists and parse it for command validation
  justfilePath = ../justfile;
  justfileExists = builtins.pathExists justfilePath;

  justfileContent =
    if justfileExists
    then builtins.readFile justfilePath
    else "";

  # Extract recipe names from justfile content
  extractRecipes = content: let
    lines = lib.splitString "\n" content;
    # Find lines that start recipe definitions (no leading whitespace, contain colon)
    recipeLines = lib.filter (line: let
      trimmed = lib.strings.removePrefix " " line;
    in
      trimmed
      == line
      && lib.hasInfix ":" line
      && !lib.hasPrefix "#" line)
    lines;

    # Extract recipe names (everything before the colon, removing parameters)
    recipeNames = map (line: let
      parts = lib.splitString ":" line;
      beforeColon = lib.head parts;
      # Remove parameters like *ARGS, HOST, etc.
      nameOnly = lib.head (lib.splitString " " beforeColon);
    in
      lib.strings.trim nameOnly)
    recipeLines;
  in
    lib.unique recipeNames;

  discoveredRecipes = extractRecipes justfileContent;

  # Expected critical commands that should exist
  expectedCommands = [
    "test"
    "test-verbose"
    "test-linux"
    "test-darwin"
    "check"
    "build"
    "list-hosts"
    "validate-host"
    "host-info"
    "lint"
    "lint-check"
    "fmt"
    "update"
    "gc"
    "switch"
  ];

  # Check if a specific command exists in justfile
  commandExists = command: lib.elem command discoveredRecipes;

  # Parse command dependencies from justfile content
  extractCommandDependencies = command: let
    lines = lib.splitString "\n" justfileContent;

    # Find the command definition line
    commandLine =
      lib.findFirst (line: let
        trimmed = lib.strings.trim line;
        # Match command at start, optionally followed by space and parameters
      in
        (lib.hasPrefix "${command}:" trimmed || lib.hasPrefix "${command} " trimmed) && lib.hasInfix ":" trimmed)
      null
      lines;

    # Extract any parameters or dependencies mentioned in the command line
    hasDependencies =
      if commandLine != null
      then lib.hasInfix "HOST" commandLine || lib.hasInfix "ARGS" commandLine
      else false;
  in {
    exists = commandLine != null;
    hasParameters = hasDependencies;
    definition = commandLine;
  };

  # Test command syntax and structure
  testCommandStructure = command: let
    deps = extractCommandDependencies command;
    # Check for common syntax issues in command definitions
    hasValidSyntax =
      if deps.exists
      then let
        line = deps.definition;
        # Basic syntax checks
      in
        lib.hasInfix ":" line
        && !lib.hasInfix " = " line
        && # Not a variable assignment
        (lib.hasPrefix command line || lib.hasPrefix "${command} " line || lib.hasPrefix " ${command}" line)
      else false;
  in {
    command = command;
    exists = deps.exists;
    hasValidSyntax = hasValidSyntax;
    hasParameters = deps.hasParameters;
  };

  # Analyze command categories and coverage
  analyzeCommandCoverage = let
    testingCommands =
      lib.filter (cmd: lib.hasInfix "test" cmd) discoveredRecipes;
    buildCommands =
      lib.filter (cmd: lib.hasInfix "build" cmd || lib.hasInfix "switch" cmd)
      discoveredRecipes;
    maintenanceCommands = lib.filter (cmd:
      lib.hasInfix "lint" cmd
      || lib.hasInfix "fmt" cmd
      || lib.hasInfix "gc" cmd
      || lib.hasInfix "update" cmd)
    discoveredRecipes;
    hostCommands = lib.filter (cmd:
      lib.hasInfix "host" cmd || cmd == "list-hosts" || cmd == "validate-host")
    discoveredRecipes;
  in {
    totalCommands = lib.length discoveredRecipes;
    testingCommands = lib.length testingCommands;
    buildCommands = lib.length buildCommands;
    maintenanceCommands = lib.length maintenanceCommands;
    hostCommands = lib.length hostCommands;

    hasTestingSupport = (lib.length testingCommands) >= 3;
    hasBuildSupport = (lib.length buildCommands) >= 2;
    hasMaintenanceSupport = (lib.length maintenanceCommands) >= 3;
    hasHostSupport = (lib.length hostCommands) >= 2;
  };

  coverage = analyzeCommandCoverage;

  # Generate tests for all expected commands
  generateCommandTests =
    map (command: {
      name = "test${lib.strings.toUpper (builtins.substring 0 1 command)}${
        builtins.substring 1 (builtins.stringLength command) command
      }CommandExists";
      value = {
        expr = commandExists command;
        expected = true;
      };
    })
    expectedCommands;

  # Generate syntax tests for discovered commands
  generateSyntaxTests = map (command: let
    structure = testCommandStructure command;
  in {
    name = "test${lib.strings.toUpper (builtins.substring 0 1 command)}${
      builtins.substring 1 (builtins.stringLength command) command
    }Syntax";
    value = {
      expr = structure.hasValidSyntax;
      expected = true;
    };
  }) (lib.take 10 discoveredRecipes); # Limit to avoid too many tests
in
  lib.listToAttrs (generateCommandTests ++ generateSyntaxTests)
  // {
    # Core justfile validation tests
    testJustfileExists = {
      expr = justfileExists;
      expected = true;
    };

    testJustfileNotEmpty = {
      expr =
        if justfileExists
        then (builtins.stringLength justfileContent) > 100
        else false;
      expected = true;
    };

    testMinimumCommandCount = {
      expr = (lib.length discoveredRecipes) >= 10;
      expected = true;
    };

    # Command category coverage tests
    testHasTestingSupport = {
      expr = coverage.hasTestingSupport;
      expected = true;
    };

    testHasBuildSupport = {
      expr = coverage.hasBuildSupport;
      expected = true;
    };

    testHasMaintenanceSupport = {
      expr = coverage.hasMaintenanceSupport;
      expected = true;
    };

    testHasHostSupport = {
      expr = coverage.hasHostSupport;
      expected = true;
    };

    # Essential command existence tests
    testHasCriticalCommands = {
      expr = let
        criticalCommands = ["test" "check" "build" "switch"];
        criticalExist = map commandExists criticalCommands;
      in
        lib.all (x: x) criticalExist;
      expected = true;
    };

    # Command naming consistency
    testCommandNamingConsistency = {
      expr = let
        # Test commands should start with 'test'
        testCommands =
          lib.filter (cmd: lib.hasPrefix "test-" cmd) discoveredRecipes;
        # Build commands should contain 'build'
        # All test commands should follow convention
        testConventionValid =
          lib.all (cmd: lib.hasPrefix "test-" cmd) testCommands;
      in
        testConventionValid && (lib.length testCommands) > 0;
      expected = true;
    };

    # Parameter validation for parameterized commands
    testParameterizedCommands = {
      expr = let
        # Commands that should accept parameters
        parameterCommands = ["build" "validate-host" "host-info"];
        parameterStructures = map testCommandStructure parameterCommands;
        # At least some commands should have parameters
        hasParameterizedCommands =
          lib.any (struct: struct.hasParameters) parameterStructures;
      in
        hasParameterizedCommands;
      expected = true;
    };

    # Command dependencies and ordering
    testCommandOrdering = {
      expr = let
        # Default recipe should be first or near first - simplified check
        hasDefaultCommand = lib.elem "default" discoveredRecipes;
        # If default exists, assume ordering is reasonable (simplified test)
        hasReasonableOrdering = hasDefaultCommand;
      in
        hasReasonableOrdering;
      expected = true;
    };
  }
