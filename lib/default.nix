{inputs, ...}:

{
  # Builder for a macOS system.
  mkDarwin = { hostname, system, user }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;

      specialArgs = {
        inherit hostname system user;
      };

      modules = [
        ../common
        ../macos
        # Users and Home Manager basics
        inputs.home-manager.darwinModules.home-manager
        ({pkgs, ...}: {
          # Enable usage of Fish as shell,
          # shell will not be set for user otherwise.
          programs.fish.enable = true;

          # nix-darwin user creation
          users.users.${user} = {
            name = user;
            home = "/Users/${user}";
            isHidden = false;
            shell = pkgs.fish;
          };

          # home-manager base configuration.
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${user} = import ../macos/home.nix { inherit pkgs; stateVersion = "23.11"; };
          };
        })
      ];
    };
}
