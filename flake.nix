{
  # Pinned to a rev, not the `nixpkgs` registry alias: a registry alias resolves
  # through whatever channel the consumer's machine points at, so the same flake
  # input built a different tree per host.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/9b008d60392981ad674e04016d25619281550a9d";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        defaultSite = import ./default.nix { inherit pkgs; };
        readmeSite = import ./src/readme.nix { inherit pkgs; };
        htmlExperiment = import ./src/htmlexpv1.nix { inherit pkgs; };

        # The surface another flake consumes: `nixstix.lib.${system}.site.buildSite`.
        lib = {
          site = import ./lib/site.nix { inherit pkgs; };
          dsl = import ./lib/dsl.nix { inherit (pkgs) lib; };
          render = import ./lib/render.nix { inherit (pkgs) lib; };
          markdown = import ./lib/markdown.nix { inherit pkgs; };
          data = import ./lib/data.nix { };
        };

        # A site is a directory of files; a link that names no file is the one
        # failure a static site cannot surface at build time, so check it.
        linkCheck = name: site: pkgs.runCommand "${name}-links" { } ''
          cd ${site}
          shopt -s globstar nullglob
          for f in **/*.html; do
            while IFS= read -r href; do
              rel="''${href#/}"
              [ -z "$rel" ] && rel=index.html
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
      in
      {
        inherit lib;

        packages = {
          default = defaultSite;
          readme = readmeSite;
          htmlexp = htmlExperiment;
        };

        checks =
          {
            default-build = defaultSite;
            multipage = pkgs.runCommand "nixstix-multipage-check" { } ''
              test -f ${defaultSite}/index.html
              test -f ${defaultSite}/experiments/htmlexpv1/index.html
              grep -q "<title>Nixstix</title>" ${defaultSite}/index.html
              grep -q "README to site, without leaving Nix." ${defaultSite}/index.html
              grep -q "HTML Experiment" ${defaultSite}/experiments/htmlexpv1/index.html
              grep -q "Shared primitives" ${defaultSite}/experiments/htmlexpv1/index.html
              touch $out
            '';
            readme = pkgs.runCommand "nixstix-readme-check" { } ''
              test -f ${readmeSite}/index.html
              grep -q "<title>Nixstix</title>" ${readmeSite}/index.html
              grep -q "small static site generator written in Nix" ${readmeSite}/index.html
              grep -q "/assets/site.css" ${readmeSite}/index.html
              touch $out
            '';
            default-links = linkCheck "nixstix" defaultSite;
            # The nav is derived from the pages: order, labels and the current
            # page's marker all come from the index, not from the page text.
            default-nav = pkgs.runCommand "nixstix-default-nav" { } ''
              grep -Fq '<nav aria-label="Primary"><a href="/" aria-current="page">Home</a><a href="/experiments/htmlexpv1/">HTML Experiment</a></nav>' ${defaultSite}/index.html
              grep -Fq '<nav aria-label="Primary"><a href="/">Home</a><a href="/experiments/htmlexpv1/" aria-current="page">HTML Experiment</a></nav>' ${defaultSite}/experiments/htmlexpv1/index.html
              touch $out
            '';
            # Attribute and text escaping, on the pure renderer.
            render-escape =
              assert lib.render.escapeHtml "<a href=\"x\">&'" == "&lt;a href=&quot;x&quot;&gt;&amp;&#39;";
              assert lib.render.renderAttrs { disabled = true; hidden = false; title = "a&b"; } == " disabled title=\"a&amp;b\"";
              pkgs.runCommand "nixstix-render-escape" { } ''
                echo "escaping and attribute rendering hold" > $out
              '';
          };
      });
}
