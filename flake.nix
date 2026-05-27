{
  description = "FrostPhoenix's nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code.url = "github:sadjow/claude-code-nix";

    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    maple-mono = {
      url = "github:subframe7536/maple-font?ref=v7.8";
      flake = false;
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superfile.url = "github:yorukot/superfile";
    zen-browser.url = "github:0xc000022070/zen-browser-flake/beta";

    astronvim-template = {
      url = "github:YangLongPH/astronvim-template";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, self, ... }@inputs:
    let
      username = "frostphoenix";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        yanglong-pc = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/yanglong-pc ];
          specialArgs = {
            host = "yanglong-pc";
            username = "yanglong";
            inherit self inputs;
          };
        };
	PC-170 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/PC-170 ];
          specialArgs = {
            host = "PC-170";
            username = "yanglong";
            inherit self inputs;
          };
        };
      };
    };
}
