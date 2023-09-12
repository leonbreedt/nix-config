{inputs, ...}:

rec {
  # Load all overlays.
  overlays = let
      path = ../overlays;
    in with builtins;
      map (n: import (path + ("/" + n)))
      (filter (n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix")))
              (attrNames (readDir path)));

  # Builder for a macOS system.
  mkDarwin = { hostname, system, user, isPersonal ? true }:
    let
      pkgs = import inputs.nixpkgs { inherit system overlays; };
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;

      specialArgs = {
        inherit pkgs hostname system user isPersonal;
        inherit (inputs) secrets;
      };

      modules = [
        ../common
        ../macos

        inputs.home-manager.darwinModules.home-manager

        {
          # System packages
          environment.systemPackages =
            (import ../common/packages.nix { inherit pkgs; })
            ++
            (import ../macos/packages.nix { inherit pkgs; });

          # Base nix-darwin user configuration, don't specify anything here
          # other than name and home dir, as nix-darwin will ignore extra
          # attributes for users it did not create, like shell.
          users.users.${user} = {
            name = user;
            home = "/Users/${user}";
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
            users.${user} =
              (import ../common/home.nix { inherit pkgs; })
              //
              (import ../macos/home.nix { inherit pkgs; });
          };
        }
      ];
    };
}
