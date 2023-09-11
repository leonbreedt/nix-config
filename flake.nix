{
  description = "NixOS, macOS and WSL system configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "git+ssh://git@github.com/leonbreedt/secrets.git";
      flake = false;
    };
  };

  outputs = {nixpkgs, nix-darwin, secrets, ...}@inputs: 
  let
    lib = import ./lib { inherit inputs; };
  in
  {
    darwinConfigurations = {
      leon-vm = lib.mkDarwin {
        system = "aarch64-darwin";
        hostname = "leon-vm";
        user = "leon";
      };
    };

    nixosConfigurations = {
    };
  };
}
