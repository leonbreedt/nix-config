{
  description = "NixOS, macOS and WSL system configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/master";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "git+ssh://git@github.com/leonbreedt/secrets.git";
      flake = false;
    };

    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
    };
  };

  outputs = {nixpkgs, nix-darwin, secrets, ...}@inputs:
  let
    lib = import ./lib {
      inherit inputs;
      inherit (nixpkgs) lib;
    };
  in
  {
    darwinConfigurations = {
      athena = lib.mkDarwin {
        hostname = "athena";
        user = "leon";
      };
      KHW90GQLQF = lib.mkDarwin {
        hostname = "KHW90GQLQF";
        user = "i070279";
        isPersonal = false;
      };
    };

    nixosConfigurations = {
      galactica-wsl = lib.mkWsl {
        hostname = "galactica";
        user = "leon";
      };

      galactica = lib.mkNixos {
        hostname = "galactica";
        user = "leon";
        useX11 = true;
        useGnome = true;
      };

      starbuck = lib.mkNixos {
        hostname = "starbuck";
        user = "leon";
      };
    };
  };
}
