{ pkgs }:
let
  lib = pkgs.lib;

  # A store-file-name-safe form of a source path.
  label = path:
    builtins.replaceStrings
    [ " " ":" "/" ]
    [ "-" "-" "-" ]
    (builtins.baseNameOf (toString path));

  specOf = spec:
    if builtins.isAttrs spec then spec
    else { source = spec; };

  # A content file's frontmatter-stripped body arrives as text, so the page
  # never needs an intermediate store file just to hold it.
  # `cat ${spec.source}`, never `toString spec.source`: toString drops the store
  # reference and the build then reads a path GC may have taken.
  produce = spec:
    if spec ? text
    then "printf '%s' ${lib.escapeShellArg spec.text}"
    else "cat ${spec.source}";
in
{
  # The node carries the SOURCE. Rendering it to html is a build step of the
  # site (see lib/site.nix), so evaluating a page never starts a build.
  fromFile = path: {
    kind = "markdown";
    source = path;
  };

  fromText = text: {
    kind = "markdown";
    inherit text;
  };

  toHtml = raw:
    let
      spec = specOf raw;
    in
    pkgs.runCommand "nixstix-md-${if spec ? source then label spec.source else "text"}" {
      nativeBuildInputs = [ pkgs.cmark-gfm ];
    } ''
      ${produce spec} | cmark-gfm -e table -t html > $out
    '';
}
