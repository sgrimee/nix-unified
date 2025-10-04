# lib/reporting/exporters.nix
# Graph format exporters for visualization tools
{lib, ...}: let
  # Generate nodes from host mapping data
  generateNodes = hostMappings: let
    # Host nodes
    hostNodes =
      lib.mapAttrsToList (hostName: hostData: {
        id = hostName;
        label = hostName;
        type = "host";
        platform = hostData.platform;
        packageCount = hostData.packageCount;
        categoryCount = lib.length hostData.categories;
      })
      hostMappings;

    # Capability nodes (grouped by host)
    capabilityNodes = lib.flatten (lib.mapAttrsToList (hostName: hostData: let
      capabilities = hostData.capabilities;
      features =
        lib.filterAttrs (_name: value: value == true) capabilities.features;
    in
      lib.mapAttrsToList (capName: _value: {
        id = "${hostName}:cap:${capName}";
        label = capName;
        type = "capability";
        host = hostName;
        category = "feature";
      })
      features) hostMappings);

    # Category nodes (grouped by host)
    categoryNodes = lib.flatten (lib.mapAttrsToList (hostName: hostData:
      map (category: {
        id = "${hostName}:cat:${category}";
        label = category;
        type = "category";
        host = hostName;
      })
      hostData.categories)
    hostMappings);

    # Package nodes (shared across hosts)
    allPackageNames = lib.unique (lib.flatten
      (lib.mapAttrsToList (_name: data: data.packageNames or [])
        hostMappings));

    packageNodes =
      map (packageName: {
        id = "pkg:${packageName}";
        label = packageName;
        type = "package";
        # Calculate which hosts use this package
        hosts = lib.filter (hostName:
          lib.elem packageName (hostMappings.${hostName}.packageNames or []))
        (lib.attrNames hostMappings);
      })
      allPackageNames;
  in
    hostNodes ++ capabilityNodes ++ categoryNodes ++ packageNodes;

  # Generate edges from host mapping data
  generateEdges = hostMappings: let
    # Host → Capability edges
    hostToCapEdges = lib.flatten (lib.mapAttrsToList (hostName: hostData: let
      capabilities = hostData.capabilities;
      features =
        lib.filterAttrs (_name: value: value == true) capabilities.features;
    in
      lib.mapAttrsToList (capName: _value: {
        source = hostName;
        target = "${hostName}:cap:${capName}";
        type = "has_capability";
      })
      features) hostMappings);

    # Host → Category edges (direct, since we don't track capability → category mapping yet)
    hostToCatEdges = lib.flatten (lib.mapAttrsToList (hostName: hostData:
      map (category: {
        source = hostName;
        target = "${hostName}:cat:${category}";
        type = "has_category";
      })
      hostData.categories)
    hostMappings);

    # Category → Package edges
    catToPkgEdges = lib.flatten (lib.mapAttrsToList (hostName: hostData:
      lib.flatten (map (category:
        map (packageName: {
          source = "${hostName}:cat:${category}";
          target = "pkg:${packageName}";
          type = "provides_package";
        }) (hostData.packageNames or []))
      hostData.categories))
    hostMappings);
  in
    hostToCapEdges ++ hostToCatEdges ++ catToPkgEdges;
in {
  # Export to GraphML format for Cytoscape.js
  toGraphML = hostMappings: let
    nodes = generateNodes hostMappings;
    edges = generateEdges hostMappings;

    # Generate GraphML node XML
    nodeXML = node: ''
      <node id="${node.id}">
        <data key="label">${node.label}</data>
        <data key="type">${node.type}</data>
        ${
        lib.optionalString (node ? platform)
        ''<data key="platform">${node.platform}</data>''
      }
        ${
        lib.optionalString (node ? host)
        ''<data key="host">${node.host}</data>''
      }
        ${
        lib.optionalString (node ? packageCount)
        ''<data key="packageCount">${toString node.packageCount}</data>''
      }
        ${
        lib.optionalString (node ? categoryCount)
        ''<data key="categoryCount">${toString node.categoryCount}</data>''
      }
        ${
        lib.optionalString (node ? hosts)
        ''<data key="hostCount">${toString (lib.length node.hosts)}</data>''
      }
      </node>'';

    # Generate GraphML edge XML
    edgeXML = edge: ''
      <edge source="${edge.source}" target="${edge.target}">
        <data key="type">${edge.type}</data>
      </edge>'';
  in ''
    <?xml version="1.0" encoding="UTF-8"?>
    <graphml xmlns="http://graphml.graphdrawing.org/xmlns"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
             http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">

      <!-- Data keys -->
      <key id="label" for="node" attr.name="label" attr.type="string"/>
      <key id="type" for="node" attr.name="type" attr.type="string"/>
      <key id="platform" for="node" attr.name="platform" attr.type="string"/>
      <key id="host" for="node" attr.name="host" attr.type="string"/>
      <key id="packageCount" for="node" attr.name="packageCount" attr.type="int"/>
      <key id="categoryCount" for="node" attr.name="categoryCount" attr.type="int"/>
      <key id="hostCount" for="node" attr.name="hostCount" attr.type="int"/>
      <key id="type" for="edge" attr.name="type" attr.type="string"/>

      <graph id="HostPackageMapping" edgedefault="directed">
        <!-- Nodes -->
        ${lib.concatStringsSep "\n      " (map nodeXML nodes)}

        <!-- Edges -->
        ${lib.concatStringsSep "\n      " (map edgeXML edges)}
      </graph>
    </graphml>
  '';

  # Export to DOT format for Graphviz
  toDOT = hostMappings: let
    nodes = generateNodes hostMappings;
    edges = generateEdges hostMappings;

    # Generate DOT node declaration
    nodeDOT = node: let
      # Style based on node type
      style =
        {
          host = "shape=box, style=filled, fillcolor=lightblue, fontsize=14";
          capability = "shape=ellipse, style=filled, fillcolor=lightcoral, fontsize=10";
          category = "shape=diamond, style=filled, fillcolor=orange, fontsize=12";
          package = "shape=circle, style=filled, fillcolor=lightgreen, fontsize=8";
        }.${
          node.type
        };

      # Escape quotes in labels
      safeLabel = lib.replaceStrings [''"''] [''\"''] node.label;
    in ''"${node.id}" [label="${safeLabel}", ${style}];'';

    # Generate DOT edge declaration
    edgeDOT = edge: ''"${edge.source}" -> "${edge.target}" [label="${edge.type}"];'';
  in ''
    digraph HostPackageMapping {
      rankdir=TB;
      node [fontname="Arial"];
      edge [fontname="Arial", fontsize=8];

      // Clustering by platform
      ${lib.concatStringsSep "\n    " (map nodeDOT nodes)}

      // Edges
      ${lib.concatStringsSep "\n    " (map edgeDOT edges)}
    }
  '';

  # Export to JSON Graph format for Sigma.js and other tools
  toJSONGraph = hostMappings: let
    nodes = generateNodes hostMappings;
    edges = generateEdges hostMappings;

    # Add numeric IDs for edges (required by some tools)
    edgesWithIds = lib.imap0 (i: edge: edge // {id = toString i;}) edges;
  in
    builtins.toJSON {
      nodes = nodes;
      edges = edgesWithIds;
      metadata = {
        generated = "nix-unified-reporting";
        timestamp = "runtime";
        hostCount = lib.length (lib.attrNames hostMappings);
        nodeCount = lib.length nodes;
        edgeCount = lib.length edges;

        # Node type breakdown
        nodeTypes =
          lib.foldl'
          (acc: node: acc // {${node.type} = (acc.${node.type} or 0) + 1;})
          {}
          nodes;

        # Edge type breakdown
        edgeTypes =
          lib.foldl'
          (acc: edge: acc // {${edge.type} = (acc.${edge.type} or 0) + 1;})
          {}
          edges;
      };
    };

  # Export to Cytoscape.js format (specialized JSON) - DISABLED per user request
  # toCytoscape = hostMappings: ...
  # (Full function commented out to remove Cytoscape.js web format support)

  # Utility function to get node/edge statistics
  getGraphStats = hostMappings: let
    nodes = generateNodes hostMappings;
    edges = generateEdges hostMappings;

    nodeTypeStats =
      lib.foldl'
      (acc: node: acc // {${node.type} = (acc.${node.type} or 0) + 1;}) {}
      nodes;

    edgeTypeStats =
      lib.foldl'
      (acc: edge: acc // {${edge.type} = (acc.${edge.type} or 0) + 1;}) {}
      edges;
  in {
    totalNodes = lib.length nodes;
    totalEdges = lib.length edges;
    nodeTypes = nodeTypeStats;
    edgeTypes = edgeTypeStats;

    # Graph density (edges / max_possible_edges)
    density = let
      maxPossibleEdges = (lib.length nodes) * (lib.length nodes - 1);
    in
      if maxPossibleEdges > 0
      then (lib.length edges * 100) / maxPossibleEdges
      else 0;
  };
}
