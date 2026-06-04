{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    ## Lsp
    nixd # nix

    ## formating
    shfmt
    treefmt
    nixfmt

    ## C / C++
    gcc
    gdb
    gef
    cmake
    gnumake
    valgrind
    llvmPackages_20.clang-tools

    ## Python
    (python3.withPackages (ps: with ps; [
      ipython
      pyyaml
    ]))

    ## Node.js
    nodejs_22

    ## Rust
    rustc
    cargo

    ## Java
    temurin-bin-11
    (lib.lowPrio temurin-bin-21)

    ## DevOps
    terraform
    lazydocker
    tmux
    glab                               # GitLab CLI

    ## Oracle
    oracle-instantclient               # sqlplus CLI + instant client libs
    sqlcl                              # Oracle SQLcl CLI
  ];
}
