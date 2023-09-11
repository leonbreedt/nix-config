{
  description = "NixOS, macOS and WSL system configuration";

  inputs = {
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    secrets = {
      url = "git+ssh://git@github.com/leonbreedt/private.git";
      flake = false;
    };
  };

  outputs = inputs: 
  let
    todo = 1;
  in
  {
    darwinConfigurations = {
      # Test VM
      "Leons-Virtual-Machine" = inputs.nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [];
        inputs = { };
        specialArgs = {
        };
      };
    };

    nixosConfigurations = {
    };
  };
}
