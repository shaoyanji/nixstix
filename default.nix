{
  runCommandWith,
  cmark-gfm,
}: let
  index = "$out/index.html";
  style = "https://cdn.jsdelivr.net/npm/yorha@1.2.0/dist/yorha.min.css";
  banner = "made in germany";
in
  runCommandWith {
    name = "marky";
    derivationArgs.nativeBuildInputs = [cmark-gfm];
  } ''
    mkdir -p $out
    echo '<link rel="stylesheet" href="${style}" type="text/css">' >> ${index}
    cat ${./README.md} | cmark-gfm  -t html >> ${index}
    echo ${banner} | cmark-gfm -t html >> ${index}
  ''
