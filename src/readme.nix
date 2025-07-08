{
  runCommandWith,
  cmark-gfm,
}: let
  index = "$out/index.html";
  style = "https://cdn.jsdelivr.net/npm/yorha@1.2.0/dist/yorha.min.css";
  footer = "footer";
in
  runCommandWith {
    name = "marky";
    derivationArgs.nativeBuildInputs = [cmark-gfm];
  } ''
    mkdir -p $out
    echo '<link rel="stylesheet" href="${style}" type="text/css">' >> ${index}
    cat ${../README.md} | cmark-gfm  -t html >> ${index}
    echo ${footer} | cmark-gfm -t html >> ${index}
  ''
