{ lib }:
let
  escapeHtml = value:
    lib.replaceStrings
    [ "&" "<" ">" "\"" "'" ]
    [ "&amp;" "&lt;" "&gt;" "&quot;" "&#39;" ]
    (builtins.toString value);

  renderAttrs = attrs:
    lib.concatStrings (
      lib.mapAttrsToList
        (name: value:
          if value == null || value == false then ""
          else if value == true then " ${name}"
          else " ${name}=\"${escapeHtml value}\"")
        attrs
    );

  renderStringNode = node:
    if node.type == "text" then escapeHtml node.value
    else if node.type == "raw" then node.value
    else if node.type == "fragment" then lib.concatMapStrings renderStringNode node.children
    else if node.type == "element" then
      "<${node.name}${renderAttrs node.attrs}>${lib.concatMapStrings renderStringNode node.children}</${node.name}>"
    else if node.type == "stylesheet" then
      "<link rel=\"stylesheet\" href=\"${escapeHtml node.href}\"${renderAttrs node.attrs}>"
    else if node.type == "script" then
      "<script src=\"${escapeHtml node.src}\"${renderAttrs node.attrs}></script>"
    else if node.type == "markdown" then
      throw "nixstix.render: a markdown node is rendered as its own build step and cannot be inlined into a string"
    else throw "nixstix.render encountered an unsupported node type";
in
rec {
  inherit escapeHtml renderAttrs;

  # Strings stay strings; markdown becomes a FILE segment, so the page is
  # assembled at build time and no eval has to read a derivation.
  segmentsOf = markdownHtml: node:
    if node == null then []
    else if node.type == "markdown" then [ { file = markdownHtml node.spec.source; } ]
    else if node.type == "fragment" || node.type == "element" then
      let
        open =
          if node.type == "element"
          then [ { str = "<${node.name}${renderAttrs node.attrs}>"; } ]
          else [];
        close =
          if node.type == "element"
          then [ { str = "</${node.name}>"; } ]
          else [];
      in
        open ++ lib.concatMap (segmentsOf markdownHtml) node.children ++ close
    else [ { str = renderStringNode node; } ];

  renderHead = page: ''
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${escapeHtml page.title}</title>
    ${lib.optionalString (page.description != null) "<meta name=\"description\" content=\"${escapeHtml page.description}\">"}
    ${lib.concatMapStrings renderStringNode page.meta}
    ${lib.concatMapStrings renderStringNode page.head}
    </head>
  '';

  pageSegments = markdownHtml: page:
    [ { str = "<!doctype html>\n<html lang=\"${escapeHtml page.lang}\"${renderAttrs page.attrs}>\n"; } ]
    ++ [ { str = renderHead page; } ]
    ++ [ { str = "\n<body>"; } ]
    ++ lib.concatMap (segmentsOf markdownHtml) page.body
    ++ [ { str = "</body>\n</html>\n"; } ];

  # String rendering, for pages that carry no markdown (tests, head nodes).
  renderNode = renderStringNode;
  renderPage = page: lib.concatStrings (map (s: s.str or (throw "nixstix.renderPage needs pageSegments for a page with markdown")) (pageSegments (p: throw "markdown not available in renderPage") page));
}
