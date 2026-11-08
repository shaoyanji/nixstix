{ pkgs }:
let
  # A store-file-name-safe form of a source path.
  label = path:
    builtins.replaceStrings
    [ " " ":" "/" ]
    [ "-" "-" "-" ]
    (builtins.baseNameOf (toString path));
in
{
  # The node carries the SOURCE. Rendering it to html is a build step of the
  # site (see lib/site.nix), so evaluating a page never starts a build.
  fromFile = path: {
    kind = "markdown";
    source = path;
  };

  toHtml = path:
    pkgs.runCommand "nixstix-md-${label path}" {
      nativeBuildInputs = [ pkgs.cmark-gfm ];
    } ''
      cmark-gfm -t html < ${path} > $out
    '';
}
