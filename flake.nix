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
        importTOML = nixpkgs.lib.importTOML;
      in {
        packages = rec {
          default = pkgs.callPackage ./default.nix {};
          htmlexp = pkgs.callPackage ./src/htmlexpv1.nix {};
          hello = pkgs.callPackage ./src/hello.nix (importTOML ./src/people.toml);
          hello-folks = hello.override {audience = "folks";};
          cv = pkgs.callPackage ./src/cv.nix {};
          readme = pkgs.callPackage ./src/readme.nix {};
          gs = pkgs.callPackage ./src/googlesheets.nix {};
        };
        devShell = pkgs.callPackage ./shell.nix {};
      }
    );
}
