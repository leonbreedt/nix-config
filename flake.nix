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
    #lib = import ./lib {
    #  inherit inputs;
    #  inherit (nixpkgs) lib;
    #};

    # Load all overlays.
    overlays = let path = ./overlays; in with builtins;
      map (n: import (path + ("/" + n)))
      (filter (n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix")))
              (attrNames (readDir path)));

    # Helper to export secrets as an attrset keyed by the file name.
    # Only for secrets representable as Nix strings.
    # keyed by the file name, having the file contents as value
    secretsAsAttrSet = with builtins; d: mapAttrs
      (f: _: if nixpkgs.lib.hasSuffix "-gpg" f then (d + "/${f}") else readFile (d + "/${f}"))
      (readDir d);


    mkNixos3 = {
      hostname,
      system ? "x86_64-linux",
      user ? "leon",
      kind ? "minimal",
      personal ? true,
      gui ? {
        enabled = false;
        environment = "bspwm";
      },
      tarsnap ? {
        enabled = false;
        dirs = [];
        key = "";
        healthcheck = "";
      },
     }: 
    let
      secretsAttrSet = secretsAsAttrSet "${secrets}";
      pkgsWithOverlays = import nixpkgs { inherit system overlays; };
    in
    nixpkgs.lib.nixosSystem {
      system = system;
      modules = [
        ./hw/${hostname}.nix
        ./nixos
        ./packages
  
        # Creates options for machine-specific configuration, which can
        # later be referenced in other modules using config.machine.NAME.
        ({ lib, ... }: {
          options.machine = {
            hostname = lib.mkOption {
              type = lib.types.str;
              default = hostname;
            };
            user = lib.mkOption {
              type = lib.types.str;
              default = user;
            };
            kind = lib.mkOption {
              type = lib.types.enum [ "development-machine" "edge-router" "unifi-controller" "minimal" ];
              default = kind;
            };
	    personal = lib.mkOption {
              type = lib.types.bool;
              default = personal;
            };
            gui = {
              enabled = lib.mkOption {
                type = lib.types.bool;
                default = gui.enabled;
              };
              environment = lib.mkOption {
                type = lib.types.enum [ "bspwm" "gnome" ];
                default = gui.environment;
              };
            };
            tarsnap = {
              enabled = lib.mkOption {
                type = lib.types.bool;
                default = tarsnap.enabled;
              };
              dirs = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = tarsnap.dirs;
              };
              key = lib.mkOption {
                type = lib.types.str;
                default = tarsnap.key;
              };
              healthcheck = lib.mkOption {
                type = lib.types.str;
                default = tarsnap.healthcheck;
              };
            };
          };
        })

        # Give all modules access to secrets without explicitly specifying it.
        {
          _module.args = { pkgs = nixpkgs.lib.mkDefault pkgsWithOverlays; secrets = secretsAttrSet; };
        }

        # Merge common and nixOS specific packages
        ({ pkgs, config, ... }: {
          environment.systemPackages = (import ./common/packages.nix { inherit pkgs config; });
        })
      ];
    };

  /*
        home-manager.nixosModules.home-manager

        #  User, package and home-manager config
        ({ lib, pkgs, ... }:
        let
          args = {};
          commonPackages = import ./common/packages.nix args;
          nixosPackages = import ./nixos/packages.nix args;
          #commonHome = import ./common/home.nix {};
          #nixosHome = import ./nixos/home.nix {};
          #commonFiles = import ./common/files.nix;
          #nixosFiles = import ./nixos/files.nix;
        in
        {
          # System packages
          environment.systemPackages = commonPackages ++ nixosPackages;

          # Managed users
          users.users.${user} = {
            isNormalUser = true;
            extraGroups = [ "wheel" "docker" ];
            name = user;
            home = "/home/${user}";
            shell = pkgs.fish;
            openssh.authorizedKeys.keys = [ secrets.ssh-authorized-key ];
          };

          # Home Manager
          #home-manager = {
          #  useGlobalPkgs = true;
          #  useUserPackages = false;
          #  #users.${user} = lib.recursiveUpdate commonHome (lib.recursiveUpdate nixosHome { home.file = lib.recursiveUpdate commonFiles nixosFiles; });
          #  users.${user} = lib.recursiveUpdate (commonHome nixosHome);
          #};
        })
      ];
    }; */

  in
  {
    # machine determines which packages are installed in addition to bare minimum.
    # by default only packages from base system are installed.

    #darwinConfigurations = {
    #  athena = lib.mkDarwin {
   #     hostname = "athena";
   #     kind = "development-machine";
   #   };

   #   KHW90GQLQF = lib.mkDarwin {
   #     hostname = "KHW90GQLQF";
#	kind = "development-machine";
#        user = "i070279";
#        personal = false;
#      };
#    };

    nixosConfigurations = {
      pegasus = mkNixos3 {
        hostname = "pegasus";
	kind = "edge-router";
        tarsnap = {
          enabled = false;
	  dirs = [ "/etc" "/root" ];
	  key = builtins.readFile "${secrets}/tarsnap-pegasus-key";
          healthcheck = builtins.readFile "${secrets}/personal-edge-router-tarsnap-hc-uuid";
        };
      };

#      starbuck = mkNixos2 {
#        hostname = "starbuck";
#	kind = "unifi-controller";
#        tarsnap = {
#          enabled = true;
#	  dirs = [ "/etc" "/root" "/var/lib/unifi/data/sites" "/var/lib/unifi/data/backup" ];
#	  key = builtins.readFile "${secrets}/tarsnap-starbuck-key";
#          healthcheck = builtins.readFile "${secrets}/personal-controller-tarsnap-hc-uuid";
#        };
#      };

#      galactica = mkNixos2 {
#        hostname = "galactica";
#        kind = "development-machine";
#        gui = {
#          enabled = true;
#          environment = "bspwm";
#        };
#        tarsnap = {
#          enabled = true;
#	  dirs = [ "/etc" "/root" ];
#	  key = builtins.readFile "${secrets}/tarsnap-galactica-key";
#          healthcheck = builtins.readFile "${secrets}/personal-desktop-tarsnap-hc-uuid";
#        };
#      };
#
#      galactica-wsl = lib.mkWsl {
#        hostname = "galactica";
#      };
    };
  };
}
