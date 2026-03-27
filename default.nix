{ pkgs ? import <nixpkgs> {} }:
let
  dsl = import ./lib/dsl.nix { inherit (pkgs) lib; };
  markdown = import ./lib/markdown.nix { inherit pkgs; };
  site = import ./lib/site.nix { inherit pkgs; };

  homePage = import ./src/pages/index.nix {
    inherit dsl markdown;
    readmePath = ./README.md;
    overviewPath = ./src/content/overview.md;
    stylesheetHref = "/assets/site.css";
  };

  experimentPage = import ./src/pages/htmlexpv1-page.nix {
    inherit dsl;
    stylesheetHref = "/assets/site.css";
  };
in
site.buildSite {
  name = "nixstix";
  pages = [
    homePage
    experimentPage
  ];
  assets = [
    ./assets
  ];
}
