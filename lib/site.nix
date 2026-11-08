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

  writeSegment = outputPath: segment:
    if segment ? file
    then "cat ${segment.file} >> \"$out/${outputPath}\""
    else "printf '%s' ${lib.escapeShellArg segment.str} >> \"$out/${outputPath}\"";

  writePageCommand = page:
    let
      outputPath = normalizeRoute page.route;
      segments = render.pageSegments markdown.toHtml page;
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
  }:
    pkgs.runCommand name {} ''
      mkdir -p "$out"
      ${lib.concatMapStringsSep "\n" writePageCommand pages}
      ${lib.concatMapStringsSep "\n" copyAssetCommand assets}
    '';

  # What a check or another flake needs without re-deriving the internals.
  inherit (render) escapeHtml;
  routes = pages: map (p: normalizeRoute p.route) pages;
}
