{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  packages = with pkgs; [
    cmark-gfm
    htmlq
    nixfmt-rfc-style
    ripgrep
  ];
}
