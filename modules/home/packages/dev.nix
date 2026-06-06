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
      opencv4
    ]))

    ## Node.js
    nodejs_22
    pnpm

    ## Rust
    rustc
    cargo

    ## Java
    temurin-bin-11
    (lib.lowPrio temurin-bin-21)

    ## VCS
    subversion

    ## DevOps
    terraform
    lazydocker
    tmux
    glab                               # GitLab CLI

    ## Oracle
    oracle-instantclient               # sqlplus CLI + instant client libs
    sqlcl                              # Oracle SQLcl CLI

    ## AWS
    awscli2
  ];
}
