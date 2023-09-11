{inputs, ...}:

{
  # Builder for a macOS system.
  mkDarwin = { hostname, system, user }:
    let
      pkgs = builtins.getAttr system inputs.nixpkgs.outputs.legacyPackages;
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;

      specialArgs = {
        inherit pkgs hostname system user;
      };

      modules = [
        ../common
        ../macos

        inputs.home-manager.darwinModules.home-manager

        {
          # Enable fish at nix-darwin level too.
          programs.fish.enable = true;

          # Base nix-darwin user configuration.
          users.users.${user} = {
            name = user;
            home = "/Users/${user}";
          };

          # nix-darwin does not change shell of already-existing
          # user, only user completely managed by it, which we will
          # never have on macOS
          system.activationScripts.postUserActivation.text = ''
            sudo chsh -s /run/current-system/sw/bin/fish ${user}
          '';

          # home-manager base configuration.
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = false;
            users.${user} = import ../macos/home.nix { inherit pkgs; stateVersion = "23.11"; };
          };
        }
      ];
    };
}
