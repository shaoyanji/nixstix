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
    else if node.type == "nav" then
      throw "nixstix.render: a nav node belongs in a page body, where the builder supplies its entries"
    else throw "nixstix.render encountered an unsupported node type";
in
rec {
  inherit escapeHtml renderAttrs;

  # A site published under a subpath (`/hub/` on GitHub project pages) has to
  # prefix its own asset and nav links, or they leave the subpath.
  prefix = ctx: path:
    if ctx.basePath != "" && lib.hasPrefix "/" path then ctx.basePath + path else path;

  # A nav slot renders from the site's own pages; only the current page is
  # marked, which is the part a hand-typed list always gets wrong.
  navSegments = ctx: node:
    let
      nav = ctx.nav;
    in
    if nav == null then []
    else
      [ { str = "<nav aria-label=\"${escapeHtml (node.label or "Primary")}\">"; } ]
      ++ lib.concatMap
      (entry:
        [
          {
            str = "<a href=\"${escapeHtml (prefix ctx entry.href)}\""
              + lib.optionalString (entry.href == nav.currentHref) " aria-current=\"page\""
              + ">";
          }
          { str = escapeHtml entry.label; }
          { str = "</a>"; }
        ])
      nav.entries
      ++ [ { str = "</nav>"; } ];

  # Strings stay strings; markdown becomes a FILE segment, so the page is
  # assembled at build time and no eval has to read a derivation.
  segmentsOf = ctx: node:
    if node == null then []
    else if node.type == "markdown" then [ { file = ctx.markdownHtml node.spec; } ]
    else if node.type == "nav" then navSegments ctx node
    else if node.type == "stylesheet" then
      [
        {
          str = "<link rel=\"stylesheet\" href=\"${escapeHtml (prefix ctx node.href)}\"${renderAttrs node.attrs}>";
        }
      ]
    else if node.type == "script" then [ { str = "<script src=\"${escapeHtml (prefix ctx node.src)}\"${renderAttrs node.attrs}></script>"; } ]
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
        open ++ lib.concatMap (segmentsOf ctx) node.children ++ close
    else [ { str = renderStringNode node; } ];

  renderHead = ctx: page: ''
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${escapeHtml page.title}</title>
    ${lib.optionalString (page.description != null) "<meta name=\"description\" content=\"${escapeHtml page.description}\">"}
    ${lib.concatStrings (map (s: s.str or (throw "nixstix.render: only strings belong in head")) (lib.concatMap (segmentsOf ctx) (page.meta ++ page.head)))}
    </head>
  '';

  pageSegments = ctx: page:
    [ { str = "<!doctype html>\n<html lang=\"${escapeHtml page.lang}\"${renderAttrs page.attrs}>\n"; } ]
    ++ [ { str = renderHead ctx page; } ]
    ++ [ { str = "\n<body>"; } ]
    ++ lib.concatMap (segmentsOf ctx) page.body
    ++ [ { str = "</body>\n</html>\n"; } ];

  # String rendering, for pages that carry no markdown and no nav slot.
  renderNode = renderStringNode;
  renderPage = page:
    lib.concatStrings (
      map
      (s: s.str or (throw "nixstix.renderPage needs pageSegments for a page with markdown or a nav slot"))
      (pageSegments { markdownHtml = p: throw "markdown not available in renderPage"; nav = null; } page)
    );
}
