{inputs, lib, ...}:

rec {
  # Load all overlays.
  overlays = let path = ../overlays; in with builtins;
      map (n: import (path + ("/" + n)))
      (filter (n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix")))
              (attrNames (readDir path)));

  # Helper to export secrets as an attrset keyed by the file name.
  # Only for secrets representable as Nix strings.
  # keyed by the file name, having the file contents as value
  secretsAsAttrSet = with builtins; d: mapAttrs
      (f: _: if lib.hasSuffix "-gpg" f then (d + "/${f}") else readFile (d + "/${f}"))
      (readDir d);

  # Builder for a NixOS system.
  mkNixos = {
      
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
      secretsAttrSet = secretsAsAttrSet "${inputs.secrets}";
      pkgsWithOverlays = import inputs.nixpkgs { inherit system overlays; };
      homedir = "/home/${user}";
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = system;
      modules = [
        ../hw/${hostname}.nix
        ../common
        ../nixos
  
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
            homedir = lib.mkOption {
              type = lib.types.str;
              default = homedir;
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
          _module.args = { pkgs = inputs.nixpkgs.lib.mkDefault pkgsWithOverlays; secrets = secretsAttrSet; };
        }

        # Import the Home Manager module
        inputs.home-manager.nixosModules.home-manager

        # Merge common and nixOS specific configuration
        ({ pkgs, lib, config, ... }:
        let
          pkgs = pkgsWithOverlays;
          secrets = secretsAttrSet;
        in {
          # Installed packages
          environment.systemPackages = 
            (import ../common/packages.nix { inherit pkgs lib config secrets; })
            ++
            (import ../nixos/packages.nix { inherit pkgs lib config secrets; });

          # Standard nixOS managed user configuration. Home Manager depends on this.
          users.users.${user} = {
            isNormalUser = true;
            extraGroups = [ "wheel" "docker" ];
            name = user;
            home = homedir;
            shell = pkgs.fish;
            openssh.authorizedKeys.keys = [ secrets.ssh-authorized-key ];
          };
 
          # Home Manager configuration. lib.recursiveUpdate will merge 
          # the overlapping configurations deeply, taking the last value
          # if it exists twice.
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = false;

            users.${user} = lib.recursiveUpdate
              (import ../common/home.nix { inherit pkgs lib config secrets; })
              (lib.recursiveUpdate
                (import ../nixos/home.nix { inherit pkgs lib config secrets; })
                {
                  home.file = lib.recursiveUpdate
                   (import ../common/files.nix { inherit pkgs lib config secrets; })
                   (import ../nixos/files.nix { inherit pkgs lib config secrets; });
                }
              );
          };
        })
      ];
    };

/*
  
  # Builder for a macOS system.
  mkDarwin = { hostname, system ? "aarch64-darwin", user, isPersonal ? true, tarsnapBackups ? false }:
    let
      pkgs = import inputs.nixpkgs { inherit system overlays; };
      secrets = secretsAsAttrSet "${inputs.secrets}";
      homedir = "/Users/${user}";
      configdir = "${homedir}/.config";
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;

      specialArgs = {
        inherit pkgs hostname system user isPersonal homedir configdir secrets tarsnapBackups;
      };

      modules = [
        ../common
        ../macos
        ../macos/lib/dock.nix

        inputs.home-manager.darwinModules.home-manager

        {
          # System packages
          environment.systemPackages =
            (import ../common/packages.nix { inherit pkgs isPersonal tarsnapBackups; })
            ++
            (import ../macos/packages.nix { inherit pkgs isPersonal tarsnapBackups; });

          # Base nix-darwin user configuration, don't specify anything here
          # other than name and home dir, as nix-darwin will ignore extra
          # attributes for users it did not create, like shell.
          users.users.${user} = {
            name = user;
            home = homedir;
          };

          # nix-darwin does not change shell of already-existing user, only
          # user completely managed by it, which we will never have on macOS
          system.activationScripts.postUserActivation.text = ''
            sudo chsh -s /run/current-system/sw/bin/fish ${user}
          '';

          # home-manager base configuration.
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = false;
            users.${user} = pkgs.lib.recursiveUpdate
              (import ../common/home.nix { inherit secrets pkgs homedir configdir isPersonal; })
              (
                pkgs.lib.recursiveUpdate
                  (import ../macos/home.nix { inherit secrets pkgs homedir configdir isPersonal; })
                  {
                    home.file = pkgs.lib.recursiveUpdate
                      (import ../common/files.nix { inherit secrets homedir configdir; })
                      (import ../macos/files.nix { inherit secrets homedir configdir; });
                  }
              );
          };
        }
      ];
    };

    # Builder for a WSL system
    mkWsl = { hostname, system ? "x86_64-linux", user, isPersonal ? true, useX11 ? false, isUnifiController ? false, tarsnapBackups ? false, tarsnapHealthCheckUUID ? "", tarsnapDirs ? [], tarsnapKey ? "" }:
    let
      pkgs = import inputs.nixpkgs { inherit system overlays; };
      secrets = secretsAsAttrSet "${inputs.secrets}";
      homedir = "/home/${user}";
      configdir = "${homedir}/.config";
      isWsl = true;
      useGnome = false;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit pkgs hostname system user isPersonal homedir configdir secrets isWsl useX11 useGnome isUnifiController tarsnapBackups tarsnapHealthCheckUUID tarsnapDirs tarsnapKey;
      };

      modules = [
        ../common
        ../nixos
        ../wsl
        ../hw/${hostname}-wsl.nix

        inputs.nixos-wsl.nixosModules.wsl
        inputs.home-manager.nixosModules.home-manager

        {
          # System packages
          environment.systemPackages =
            (import ../common/packages.nix { inherit pkgs homedir isPersonal isWsl useX11 useGnome isUnifiController tarsnapBackups tarsnapHealthCheckUUID tarsnapDirs tarsnapKey; })
            ++
            (import ../nixos/packages.nix { inherit pkgs homedir isPersonal isWsl useX11 useGnome isUnifiController tarsnapBackups tarsnapHealthCheckUUID tarsnapDirs tarsnapKey; });

          # Standard nixOS managed user configuration
          users.users.${user} = {
            isNormalUser = true;
            extraGroups = [ "wheel" "docker" ];
            name = user;
            home = homedir;
            shell = pkgs.fish;
	        openssh.authorizedKeys.keys = [ secrets.ssh-authorized-key ];
          };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = false;

            users.${user} = pkgs.lib.recursiveUpdate
              (import ../common/home.nix { inherit secrets pkgs homedir configdir isPersonal isWsl useX11 useGnome isUnifiController tarsnapBackups tarsnapHealthCheckUUID tarsnapDirs tarsnapKey; })
              (
                pkgs.lib.recursiveUpdate
                  (import ../nixos/home.nix { inherit secrets pkgs homedir configdir isPersonal isWsl useX11 useGnome isUnifiController tarsnapBackups tarsnapHealthCheckUUID tarsnapDirs tarsnapKey; })
                  {
                    home.file = pkgs.lib.recursiveUpdate
                      (import ../common/files.nix { inherit secrets homedir configdir isWsl useX11 useGnome isUnifiController tarsnapBackups tarsnapHealthCheckUUID tarsnapDirs tarsnapKey; })
                      (import ../nixos/files.nix { inherit secrets homedir configdir isWsl useX11 useGnome isUnifiController tarsnapBackups tarsnapHealthCheckUUID tarsnapDirs tarsnapKey; });
                  }
              );
          };
        }
      ];
    };
  */

}
