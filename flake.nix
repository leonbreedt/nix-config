{
  description = "NixOS, macOS and WSL system configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/release-24.11";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
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

  outputs = {nixpkgs, nix-darwin, secrets, home-manager, ...}@inputs:
  let
    lib = import ./lib {
      inherit inputs;
      inherit (nixpkgs) lib;
    };
  in
  {
    nixosConfigurations = {
      pegasus = lib.mkNixos {
        hostname = "pegasus";
	kind = "edge-router";
        tarsnap = {
          enabled = true;
	  dirs = [ "/etc" "/root" ];
	  key = builtins.readFile "${secrets}/tarsnap-pegasus-key";
          healthcheck = builtins.readFile "${secrets}/personal-edge-router-tarsnap-hc-uuid";
        };
      };
      starbuck = lib.mkNixos {
        hostname = "starbuck";
        kind = "unifi-controller";
        tarsnap = {
          enabled = true;
          dirs = [ "/etc" "/root" "/var/lib/unifi/data/sites" "/var/lib/unifi/data/backup" ];
          key = builtins.readFile "${secrets}/tarsnap-starbuck-key";
          healthcheck = builtins.readFile "${secrets}/personal-controller-tarsnap-hc-uuid";
        };
      };
      galactica = lib.mkNixos {
        hostname = "galactica";
        kind = "development-machine";
        gui = {
          enabled = true;
          environment = "bspwm";
        };
        tarsnap = {
          enabled = true;
          dirs = [ "/etc" "/root" ];
          key = builtins.readFile "${secrets}/tarsnap-galactica-key";
          healthcheck = builtins.readFile "${secrets}/personal-desktop-tarsnap-hc-uuid";
        };
      };
    };

    #darwinConfigurations = {
    #  athena = lib.mkDarwin {
    #    hostname = "athena";
    #    kind = "development-machine";
    #  };
    #  KHW90GQLQF = lib.mkDarwin {
    #    hostname = "KHW90GQLQF";
    #    kind = "development-machine";
    #    user = "i070279";
    #    personal = false;
    #  };
    #};
  };
}
