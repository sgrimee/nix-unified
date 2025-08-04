# packages/discovery.nix
{ lib, ... }:

{
  # Generate package documentation
  generatePackageDocs = categories:
    let
      categoryDocs = lib.mapAttrs (name: category: {
        inherit name;
        description = category.metadata.description or "";
        packages = {
          core = map (pkg: pkg.pname or (toString pkg)) (category.core or [ ]);
          utilities =
            map (pkg: pkg.pname or (toString pkg)) (category.utilities or [ ]);
        };
        size = category.metadata.size or "medium";
        conflicts = category.metadata.conflicts or [ ];
        requires = category.metadata.requires or [ ];
      }) categories;
    in categoryDocs;

  # Search packages across categories
  searchPackages = searchTerm: categories:
    let
      allPackages = lib.flatten (lib.mapAttrsToList (catName: category:
        map (pkg: {
          name = pkg.pname or (toString pkg);
          category = catName;
          description = pkg.meta.description or "";
        }) (lib.flatten
          (lib.attrValues (lib.filterAttrs (_n: v: lib.isList v) category))))
        categories);

      matchingPackages = lib.filter (pkg:
        lib.hasInfix (lib.toLower searchTerm) (lib.toLower pkg.name)
        || lib.hasInfix (lib.toLower searchTerm) (lib.toLower pkg.description))
        allPackages;

    in matchingPackages;
}
