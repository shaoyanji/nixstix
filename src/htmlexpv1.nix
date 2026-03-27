{ pkgs ? import <nixpkgs> {} }:
let
  dsl = import ../lib/dsl.nix { inherit (pkgs) lib; };
  site = import ../lib/site.nix { inherit pkgs; };

  page = import ./pages/htmlexpv1-page.nix {
    inherit dsl;
    stylesheetHref = "/assets/site.css";
  };
in
site.buildSite {
  name = "nixstix-htmlexp";
  pages = [ page ];
  assets = [ ../assets ];
}
