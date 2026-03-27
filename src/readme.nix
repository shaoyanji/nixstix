{ pkgs ? import <nixpkgs> {} }:
let
  dsl = import ../lib/dsl.nix { inherit (pkgs) lib; };
  markdown = import ../lib/markdown.nix { inherit pkgs; };
  site = import ../lib/site.nix { inherit pkgs; };

  page = import ./pages/index.nix {
    inherit dsl markdown;
    readmePath = ../README.md;
    overviewPath = null;
    stylesheetHref = "/assets/site.css";
  };
in
site.buildSite {
  name = "nixstix-readme";
  pages = [ page ];
  assets = [ ../assets ];
}
