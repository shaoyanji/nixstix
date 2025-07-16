{
  runCommandWith,
  cmark-gfm,
}: let
  index = "$out/index.html";
  style = "https://cdn.jsdelivr.net/npm/yorha@1.2.0/dist/yorha.min.css";
  script = "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js";
  unsafe = ''<h1 x-data='{ message: "I ❤️ Alpine" }' x-text='message'></h1>'';
  unsafe2 = ''    <div x-data='{ open: false }'>
        <button @click='open = ! open'>Toggle</button>
         <div x-show='open' @click.outside='open = false'>Contents...</div>
    </div>'';
  banner = ''\</body\>made in germany'';
in
  runCommandWith {
    name = "marky";
    derivationArgs.nativeBuildInputs = [cmark-gfm];
  } ''
        mkdir -p $out
        echo "<head>" >> ${index}
        echo '<link rel="stylesheet" href="${style}" type="text/css">' >> ${index}
    echo '<script defer src="${script}"></script>' >> ${index}
        echo "</head><body>" >> ${index}
         cat ${./README.md} | cmark-gfm  -t html >> ${index}
    echo "${unsafe}"  >> ${index}
    echo "${unsafe2}" >> ${index}
        echo ${banner} | cmark-gfm --unsafe -t html >> ${index}
  ''
