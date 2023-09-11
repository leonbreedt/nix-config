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
          # Needs to be turned off at nix-darwin level.
          programs = { };

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
        }
      ];
    };
}
