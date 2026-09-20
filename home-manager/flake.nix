{
  description = "Home Manager configuration of commander";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
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
        extraSpecialArgs = { inherit machine; };

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}
