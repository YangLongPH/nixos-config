{ pkgs, lib, inputs, ... }:
{
  home.packages = with pkgs; [
    ## AI coding agents
    codex                                          # OpenAI Codex CLI
    inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity-cli  # Antigravity CLI (agy)

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
    jetbrains.idea-oss

    ## .NET
    dotnet-sdk_10

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
