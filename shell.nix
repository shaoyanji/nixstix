{pkgs ? <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    yj
    comrak
    # cmark-gfm
    # tgpt
    # go-task
    # yq-go
    # fzf
  ];
}
