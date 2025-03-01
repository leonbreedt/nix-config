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

  outputs = {nixpkgs, nix-darwin, secrets, home-manager, ...}@inputs:
  let
    #lib = import ./lib {
    #  inherit inputs;
    #  inherit (nixpkgs) lib;
    #};

    mkNixos2 = opts: nixpkgs.lib.nixosSystem {
      system = opts.system ? "x86_64-linux";
      modules = [
        # creates options for machine customization.
        ({ lib, ... }: {
          options.machine = {
            hostname = lib.mkOption {
              type = lib.types.str;
              default = opts.hostname ? null;
            };
            
            kind = lib.mkOption {
              type = lib.types.oneOf [ "development-machine" "edge-router" "unifi-controller" "minimal" ];
              default = opts.kind ? "minimal";
            };

            user = lib.mkOption {
              type = lib.types.str;
              default = opts.user ? "leon";
            };

            personal = lib.mkOption {
              type = lib.types.bool;
              default = opts.personal ? true;
            };

            gui = {
              enabled = lib.mkOption {
                type = lib.types.bool;
                default = opts.gui.enabled ? false;
              };

              environment = lib.mkOption {
                type = lib.types.oneOf [ "bspwm" "gnome" ];
                default = opts.gui.environment ? "bspwm";
              };
            };

            tarsnap = {
              enabled = lib.mkOption {
                type = lib.types.bool;
                default = opts.tarsnap.enabled ? false;
              };

              dirs = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = opts.tarsnap.dirs ? [ ];
              };

              key = lib.mkOption {
                type = lib.types.str;
                default = opts.tarsnap.key ? "";
              };

              healthcheck = lib.mkOption {
                type = lib.types.str;
                default = opts.tarsnap.healthcheck ? "";
              };
            };
          };
        })

        ./hw/${opts.hostname}.nix
        ../common
        ../nixos

        home-manager.nixosModules.home-manager

        #  User, package and home-manager config
        {
          # System packages
          environment.systemPackages = (import ../common/packages.nix) ++ (import ../nixos/packages.nix)

          # Managed users
          users.users.${opts.user} = {
            isNormalUser = true;
            extraGroups = [ "wheel" "docker" ];
            name = opts.user;
            home = "/home/${opts.user}";
            shell = pkgs.fish;
            openssh.authorizedKeys.keys = [ secrets.ssh-authorized-key ];
          };

          # Home Manager
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = false;
            users.${opts.user} = lib.recursiveUpdate
              (import ../common/home.nix)
              (lib.recursiveUpdate
                (import ../nixos/home.nix)
                {
                  home.file = lib.recursiveUpdate
                    (import ../common/files.nix)
                    (import ../nixos/files.nix);
                }
              );
          };
        }
      ];
    };
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
      pegasus = mkNixos2 {
        hostname = "pegasus";
	kind = "edge-router";
        tarsnap = {
          enabled = true;
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
