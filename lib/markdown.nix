{ pkgs }:
let
  sanitizeName = path:
    let
      base = builtins.baseNameOf (toString path);
    in
    builtins.replaceStrings
      [ "/" " " ":" ]
      [ "-" "-" "-" ]
      base;

  renderFile = path:
    builtins.readFile (pkgs.runCommand "${sanitizeName path}.html" {
      nativeBuildInputs = [ pkgs.cmark-gfm ];
    } ''
      cmark-gfm -t html < ${path} > $out
    '');
in
{
  fromFile = path: {
    kind = "markdown";
    source = path;
    html = renderFile path;
  };
}
