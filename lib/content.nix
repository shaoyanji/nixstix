# The content step: a directory of markdown files IS a set of pages.
#
#   src/content/overview.md                  -> /overview/
#   src/content/guide/content-directory.md   -> /guide/content-directory/
#   src/content/guide/index.md               -> /guide/
#
# Nothing here is declared twice: the route comes from the path, and the few
# facts a page needs (title, description, nav label and order) come from a
# frontmatter block in the file itself. A page module is still allowed — this
# step only removes the requirement to write one.
{
  lib,
  dsl,
  markdown,
}:
let
  isMarker = line: lib.trim line == "---";

  unquote = value:
    let
      first = builtins.substring 0 1 value;
    in
    if builtins.stringLength value >= 2
    && (first == "\"" || first == "'")
    && builtins.substring (builtins.stringLength value - 1) 1 value == first
    then builtins.substring 1 (builtins.stringLength value - 2) value
    else value;

  parseValue = raw:
    let
      value = lib.trim raw;
    in
    if value == "true" then true
    else if value == "false" then false
    else if builtins.match "[0-9]+" value != null then lib.toInt value
    else unquote value;

  parseLines = lines:
    let
      relevant = builtins.filter
        (line:
          let
            trimmed = lib.trim line;
          in
          trimmed != "" && !(lib.hasPrefix "#" trimmed))
        lines;
      entries = map
        (line:
          let
            parsed = builtins.match "([^:]+):[ \t]*(.*)" line;
          in
          if parsed == null
          then throw "nixstix.content: frontmatter line is not key: value — ${line}"
          else {
            name = lib.trim (builtins.head parsed);
            value = parseValue (builtins.elemAt parsed 1);
          })
        relevant;
    in
    lib.listToAttrs entries;

  # `---` opens a block only on the first line; an unclosed block is an error,
  # because swallowing it would publish the keys as prose.
  splitFrontmatter = text:
    let
      all = lib.splitString "\n" text;
      takeUntilClose = acc: remaining:
        if remaining == []
        then null
        else if isMarker (builtins.head remaining)
        then {
          front = acc;
          body = builtins.tail remaining;
        }
        else takeUntilClose (acc ++ [ (builtins.head remaining) ]) (builtins.tail remaining);
    in
    if all == [] || !(isMarker (builtins.head all))
    then {
      meta = { };
      body = text;
    }
    else
      let
        closed = takeUntilClose [] (builtins.tail all);
      in
      if closed == null
      then {
        meta = null;
        body = null;
      }
      else {
        meta = parseLines closed.front;
        body = lib.concatStringsSep "\n" closed.body;
      };

  markdownFiles = dir: prefix:
    let
      entries = builtins.readDir dir;
    in
    builtins.concatMap
      (name:
        let
          entry = entries.${name};
        in
        # `_` marks a partial: a body another page pulls in, not a page of its
        # own (`_index.md`), so it is read but never routed.
        if lib.hasPrefix "." name || lib.hasPrefix "_" name then []
        else if entry == "directory" then markdownFiles (dir + "/${name}") "${prefix}${name}/"
        else if entry == "regular" && lib.hasSuffix ".md" name
        then [{
          path = dir + "/${name}";
          rel = "${prefix}${name}";
        }]
        else [])
      (builtins.attrNames entries);

  routeOf = rel:
    let
      stem = lib.removeSuffix ".md" rel;
      base = builtins.baseNameOf stem;
      parent = builtins.dirOf stem;
    in
    if base == "index"
    then (if parent == "." then "/" else "/${parent}/")
    else "/${stem}/";

  # A page with no frontmatter title still knows what it is called: its first
  # heading, else its file name.
  headingOf = body:
    let
      found = lib.findFirst
        (line: builtins.match "#+[ \t]+(.+)" (lib.trim line) != null)
        null
        (lib.splitString "\n" body);
    in
    if found == null then null else builtins.head (builtins.match "#+[ \t]+(.+)" (lib.trim found));

  deSlug = rel:
    let
      words = lib.replaceStrings [ "-" "_" ] [ " " " " ] (lib.removeSuffix ".md" (builtins.baseNameOf rel));
    in
    lib.toUpper (builtins.substring 0 1 words) + builtins.substring 1 (builtins.stringLength words - 1) words;

  defaultLayout = { page, content, site }:
    let
      inherit (dsl) el nav text;
    in
    el "div" { class = "page-shell"; } [
      (el "header" { class = "site-header"; } [
        (el "div" { class = "site-title"; } [ (text (site.title or page.title)) ])
        (nav { })
      ])
      (el "main" { } [
        (el "article" { class = "content"; } [
          (el "h1" { } [ (text page.title) ])
          content
        ])
      ])
    ];

  pageOf = {
    site,
    layout,
    head,
    defaultNavOrder,
    entry,
  }:
    let
      doc = splitFrontmatter (builtins.readFile entry.path);
      meta =
        if doc.meta == null
        then throw "nixstix.content: ${toString entry.path} opens frontmatter with --- and never closes it"
        else doc.meta;
      heading = headingOf doc.body;
      title =
        if meta ? title then meta.title
        else if heading != null then heading
        else deSlug entry.rel;
      page = {
        inherit title;
        route = meta.route or (routeOf entry.rel);
        description = meta.description or null;
        navLabel = meta.navLabel or title;
        navOrder = meta.navOrder or defaultNavOrder;
        showInNav = meta.showInNav or true;
      };
    in
    dsl.page (page
      // {
        inherit head;
        body = layout {
          inherit page site;
          content = dsl.markdown (markdown.fromText doc.body);
        };
      });
in
{
  inherit defaultLayout splitFrontmatter routeOf;

  # Every markdown file under `dir` becomes one page; `layout` decides how a
  # body sits inside a document, and `head` is shared by all of them.
  pages = {
    dir,
    site ? { },
    layout ? defaultLayout,
    head ? [ ],
    defaultNavOrder ? 100,
  }:
    map
      (entry: pageOf {
        inherit site layout head defaultNavOrder;
        entry = entry;
      })
      (markdownFiles dir "");
}
