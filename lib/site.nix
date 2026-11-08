{ pkgs }:
let
  lib = pkgs.lib;
  render = import ./render.nix { inherit lib; };
  markdown = import ./markdown.nix { inherit pkgs; };

  hasExtension = route:
    builtins.match ".*\\.[^/]+$" route != null;

  normalizeRoute = route:
    let
      cleaned = lib.removePrefix "/" route;
    in
    if cleaned == "" then "index.html"
    else if lib.hasSuffix "/" cleaned then "${cleaned}index.html"
    else if hasExtension cleaned then cleaned
    else "${cleaned}/index.html";

  normalizeAsset = asset:
    if lib.isAttrs asset then
      {
        source = asset.source;
        target = asset.target or (builtins.baseNameOf (toString asset.source));
      }
    else
      {
        source = asset;
        target = builtins.baseNameOf (toString asset);
      };

  hrefOf = route:
    let
      normalized = normalizeRoute route;
    in
    if normalized == "index.html" then "/"
    else if lib.hasSuffix "/index.html" normalized then "/" + lib.removeSuffix "index.html" normalized
    else "/" + normalized;

  # The index IS the nav: one entry per page that asks to appear, ordered by
  # `navOrder`, labelled by `navLabel`. Nothing is typed twice.
  navOf = pages:
    lib.sort (a: b: a.order < b.order) (
      map
      (p: {
        href = hrefOf p.route;
        label = p.navLabel;
        order = p.navOrder;
      })
      (lib.filter (p: p.showInNav) pages)
    );

  writeSegment = outputPath: segment:
    if segment ? file
    then "cat ${segment.file} >> \"$out/${outputPath}\""
    else "printf '%s' ${lib.escapeShellArg segment.str} >> \"$out/${outputPath}\"";

  writePageCommand = basePath: pages: page:
    let
      outputPath = normalizeRoute page.route;
      segments = render.pageSegments {
        markdownHtml = markdown.toHtml;
        inherit basePath;
        nav = {
          entries = navOf pages;
          currentHref = hrefOf page.route;
        };
      } page;
    in
    ''
      mkdir -p "$(dirname "$out/${outputPath}")"
      : > "$out/${outputPath}"
      ${lib.concatMapStringsSep "\n" (writeSegment outputPath) segments}
    '';

  copyAssetCommand = asset:
    let
      normalized = normalizeAsset asset;
      sourcePath = toString normalized.source;
      isDirectory = builtins.pathExists "${sourcePath}/.";
    in
    if isDirectory then
      ''
        mkdir -p "$out/${normalized.target}"
        cp -R ${normalized.source}/. "$out/${normalized.target}/"
      ''
    else
      ''
        mkdir -p "$(dirname "$out/${normalized.target}")"
        cp ${normalized.source} "$out/${normalized.target}"
      '';
in
{
  buildSite = {
    name ? "nixstix-site",
    pages,
    assets ? [],
    # A site served under a subpath (`/hub` on GitHub project pages) prefixes its
    # own asset and nav links with this; page-local links are the page's business.
    basePath ? "",
  }:
    pkgs.runCommand name {} ''
      mkdir -p "$out"
      ${lib.concatMapStringsSep "\n" (writePageCommand basePath pages) pages}
      ${lib.concatMapStringsSep "\n" copyAssetCommand assets}
    '';

  # What a check or another flake needs without re-deriving the internals.
  inherit (render) escapeHtml;
  routes = pages: map (p: normalizeRoute p.route) pages;
  nav = navOf;
}
