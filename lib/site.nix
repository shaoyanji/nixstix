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

  # A site is a directory of files, and a link that names no file is the one
  # failure a static site cannot surface at build time. Root-relative links are
  # resolved against the output tree; external ones are left alone. `basePath`
  # is the subpath the site is published under (`/hub` on project pages), and a
  # link outside it is a failure in its own right.
  checkLinks = {
    name ? "site",
    basePath ? "",
  }: site:
    pkgs.runCommand "${name}-links" { } ''
      cd ${site}
      shopt -s globstar nullglob
      base=${lib.escapeShellArg basePath}
      for f in **/*.html; do
        while IFS= read -r href; do
          rel="''${href#/}"
          if [ -n "$base" ]; then
            case "$href" in
              "$base"|"$base"/) rel="" ;;
              "$base"/*) rel="''${href#"$base"/}" ;;
              *) echo "link outside $base: $f -> $href" >&2; exit 1 ;;
            esac
          fi
          if [ -z "$rel" ]; then rel=index.html; fi
          case "$rel" in
            */) rel="''${rel}index.html" ;;
          esac
          if [ ! -e "$rel" ]; then
            echo "broken link: $f -> $href" >&2
            exit 1
          fi
        done < <(grep -o 'href="/[^"]*"' "$f" | cut -d'"' -f2)
      done
      touch $out
    '';
}
