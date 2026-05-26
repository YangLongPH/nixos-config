{ pkgs, ... }:
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
    python3
    python312Packages.ipython

    ## Node.js
    nodejs_22

    ## Rust
    rustc
    cargo

    ## Java
    temurin-bin-21

    ## DevOps
    terraform
    lazydocker
    tmux
    glab                               # GitLab CLI
  ];
}
