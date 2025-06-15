{
  lib,
  pkgs,
  ...
}: {
  # Test string utilities
  testStringConcatenation = {
    expr = "hello" + " " + "world";
    expected = "hello world";
  };
  
  testStringLength = {
    expr = builtins.stringLength "test";
    expected = 4;
  };
  
  # Test list utilities
  testListLength = {
    expr = builtins.length [ 1 2 3 ];
    expected = 3;
  };
  
  testListHead = {
    expr = builtins.head [ "first" "second" ];
    expected = "first";
  };
  
  testListTail = {
    expr = builtins.tail [ "first" "second" "third" ];
    expected = [ "second" "third" ];
  };
  
  # Test attribute set utilities
  testAttrSetHasKey = {
    expr = builtins.hasAttr "test" { test = "value"; };
    expected = true;
  };
  
  testAttrSetMissing = {
    expr = builtins.hasAttr "missing" { test = "value"; };
    expected = false;
  };
  
  testAttrNames = {
    expr = builtins.sort (a: b: a < b) (builtins.attrNames { b = 2; a = 1; c = 3; });
    expected = [ "a" "b" "c" ];
  };
  
  # Test path utilities
  testPathExists = {
    expr = builtins.pathExists ../.;
    expected = true;
  };
  
  testNonexistentPath = {
    expr = builtins.pathExists ../nonexistent;
    expected = false;
  };
  
  # Test type checking
  testTypeOfString = {
    expr = builtins.typeOf "string";
    expected = "string";
  };
  
  testTypeOfList = {
    expr = builtins.typeOf [];
    expected = "list";
  };
  
  testTypeOfAttrSet = {
    expr = builtins.typeOf {};
    expected = "set";
  };
  
  testTypeOfInt = {
    expr = builtins.typeOf 42;
    expected = "int";
  };
  
  testTypeOfBool = {
    expr = builtins.typeOf true;
    expected = "bool";
  };
  
  # Test lib functions
  testLibVersion = {
    expr = builtins.typeOf lib.version;
    expected = "string";
  };
  
  testLibHasAttr = {
    expr = lib.hasAttr "hasAttr" lib;
    expected = true;
  };
}