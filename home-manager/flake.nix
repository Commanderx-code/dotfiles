{
  description = "Home Manager configuration of commander";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ZapFast (native WhatsApp client) is not in nixpkgs; build its own flake.
    zapfast = {
      url = "github:crmne/zapfast";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Lets Nix-built GUI apps find graphics drivers on a non-NixOS host.
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Declares Plasma settings (colour scheme, fonts) from Home Manager.
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      zapfast,
      nixgl,
      plasma-manager,
      ...
    }:
    let
      machine = builtins.fromJSON (builtins.readFile ./machine.json);
      system = machine.system;
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter.${system} = pkgs.nixfmt;
      packages.${system} = import ./terminal-tools.nix { inherit pkgs; };
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          fish
          jq
          python3
          gnupg
          shellcheck
          actionlint
          nixfmt
          neovim
          eza
          ripgrep
        ];
      };
      homeConfigurations.${machine.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit machine;
          inherit nixgl;
          zapfast = zapfast.packages.${system}.default;
        };

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          plasma-manager.homeModules.plasma-manager
          ./home.nix
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}
