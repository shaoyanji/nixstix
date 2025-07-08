{pkgs ? import <nixpkgs> {}}: let
  index = pkgs.writeText "index.html" ''
    <h1>index</h1>
  '';

  postA = pkgs.writeText "postA" ''
    <h1>postA</h1>
  '';
  postB = pkgs.writeText "postB" ''
    <h1>postB</h1>
  '';
  posts = pkgs.linkFarm "posts" [
    {
      name = "a.html";
      path = postA;
    }
    {
      name = "b.html";
      path = postB;
    }
  ];
  body = ./src/posts/a.md;
in
  pkgs.linkFarm "website" [
    {
      name = "index.html";
      path = index;
    }
    {
      name = "posts";
      path = posts;
    }
  ]
# builtins.readFile (pkgs.runCommandLocal "postA" {
#     # inherit body;
#     # passAsFile = ["body"];
#     buildInputs = with pkgs; [
#       cmark
#     ];
#   } ''
#     ${pkgs.cmark}/bin/cmark -t html "$body" > $out
#   '')

