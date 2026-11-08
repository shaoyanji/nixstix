{ pkgs ? import <nixpkgs> {} }:
let
  dsl = import ./lib/dsl.nix { inherit (pkgs) lib; };
  markdown = import ./lib/markdown.nix { inherit pkgs; };
  content = import ./lib/content.nix { inherit (pkgs) lib; inherit dsl markdown; };
  site = import ./lib/site.nix { inherit pkgs; };

  homePage = import ./src/pages/index.nix {
    inherit dsl markdown;
    readmePath = ./README.md;
    stylesheetHref = "/assets/site.css";
  };

  experimentPage = import ./src/pages/htmlexpv1-page.nix {
    inherit dsl;
    stylesheetHref = "/assets/site.css";
  };

  # Every markdown file under src/content is a page; nothing here names them.
  contentPages = content.pages {
    dir = ./src/content;
    site = { title = "nixstix"; };
    head = [ (dsl.stylesheet "/assets/site.css") ];
  };
in
site.buildSite {
  name = "nixstix";
  pages = [
    homePage
    experimentPage
  ] ++ contentPages;
  assets = [
    ./assets
  ];
}
