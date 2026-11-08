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

        dsl = import ./lib/dsl.nix { inherit (pkgs) lib; };
        markdown = import ./lib/markdown.nix { inherit pkgs; };
        site = import ./lib/site.nix { inherit pkgs; };
        content = import ./lib/content.nix { inherit (pkgs) lib; inherit dsl markdown; };

        defaultSite = import ./default.nix { inherit pkgs; };
        readmeSite = import ./src/readme.nix { inherit pkgs; };
        htmlExperiment = import ./src/htmlexpv1.nix { inherit pkgs; };

        # The surface another flake consumes: `nixstix.lib.${system}.*`.
        lib = {
          inherit content dsl markdown site;
          render = import ./lib/render.nix { inherit (pkgs) lib; };
          data = import ./lib/data.nix { };
        };
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
            default-links = site.checkLinks { name = "nixstix"; } defaultSite;
            # The nav is derived from the pages: order, labels and the current
            # page's marker all come from the index, not from the page text.
            default-nav = pkgs.runCommand "nixstix-default-nav" { } ''
              grep -Fq '<nav aria-label="Primary"><a href="/" aria-current="page">Home</a><a href="/overview/">Overview</a><a href="/experiments/htmlexpv1/">HTML Experiment</a><a href="/guide/content-directory/">Content Directory</a></nav>' ${defaultSite}/index.html
              grep -Fq '<nav aria-label="Primary"><a href="/">Home</a><a href="/overview/" aria-current="page">Overview</a><a href="/experiments/htmlexpv1/">HTML Experiment</a><a href="/guide/content-directory/">Content Directory</a></nav>' ${defaultSite}/overview/index.html
              touch $out
            '';
            # The content step: path -> route, frontmatter -> page facts, and the
            # frontmatter never reaches the output.
            content-routes = pkgs.runCommand "nixstix-content-routes" { } ''
              test -f ${defaultSite}/overview/index.html
              test -f ${defaultSite}/guide/content-directory/index.html
              grep -q '<title>Overview</title>' ${defaultSite}/overview/index.html
              grep -q '<title>Content directory</title>' ${defaultSite}/guide/content-directory/index.html
              grep -q 'Thin by design' ${defaultSite}/overview/index.html
              grep -q '<h1>Overview</h1>' ${defaultSite}/overview/index.html
              if grep -q 'navOrder\|title: Overview' ${defaultSite}/overview/index.html; then
                echo 'frontmatter leaked into the page' >&2
                exit 1
              fi
              touch $out
            '';
            # Route and frontmatter rules, pure: no build, no files.
            content-pure =
              assert content.routeOf "index.md" == "/";
              assert content.routeOf "overview.md" == "/overview/";
              assert content.routeOf "guide/intro.md" == "/guide/intro/";
              assert content.routeOf "guide/index.md" == "/guide/";
              assert (content.splitFrontmatter "---\ntitle: X\nnavOrder: 3\nshowInNav: false\n---\nbody").meta == {
                title = "X";
                navOrder = 3;
                showInNav = false;
              };
              assert (content.splitFrontmatter "---\ntitle: X\n---\nbody").body == "body";
              assert (content.splitFrontmatter "no frontmatter").meta == { };
              assert (content.splitFrontmatter "---\ntitle: unterminated\n").meta == null;
              pkgs.runCommand "nixstix-content-pure" { } ''
                echo "content routing and frontmatter hold" > $out
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
