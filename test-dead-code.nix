# Test file with dead code to verify pre-push hook
let
  unusedVariable = "this should be caught by lint";
  usedVariable = "this is used";
in
{
  result = usedVariable;
}