{
  inputs = {
    utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          default = pkgs.callPackage ./default.nix {};
          readme = pkgs.callPackage ./src/readme.nix {};
          gs = pkgs.callPackage ./src/googlesheets.nix {};
        };
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            cmark-gfm
            tgpt
            go-task
            yq-go
            fzf
          ];
        };
      }
    );
}
