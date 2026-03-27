{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        defaultSite = import ./default.nix { inherit pkgs; };
        readmeSite = import ./src/readme.nix { inherit pkgs; };
        htmlExperiment = import ./src/htmlexpv1.nix { inherit pkgs; };
      in
      {
        packages = {
          default = defaultSite;
          readme = readmeSite;
          htmlexp = htmlExperiment;
        };

        checks = {
          default-build = defaultSite;
          multipage = pkgs.runCommand "nixstix-multipage-check" {} ''
            test -f ${defaultSite}/index.html
            test -f ${defaultSite}/experiments/htmlexpv1/index.html
            grep -q "<title>Nixstix</title>" ${defaultSite}/index.html
            grep -q "README to site, without leaving Nix." ${defaultSite}/index.html
            grep -q "HTML Experiment" ${defaultSite}/experiments/htmlexpv1/index.html
            grep -q "Shared primitives" ${defaultSite}/experiments/htmlexpv1/index.html
            touch $out
          '';
          readme = pkgs.runCommand "nixstix-readme-check" {} ''
            test -f ${readmeSite}/index.html
            grep -q "<title>Nixstix</title>" ${readmeSite}/index.html
            grep -q "small static site generator written in Nix" ${readmeSite}/index.html
            grep -q "/assets/site.css" ${readmeSite}/index.html
            touch $out
          '';
        };

        devShells.default = import ./shell.nix { inherit pkgs; };
      });
}
