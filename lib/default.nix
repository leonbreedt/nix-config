{inputs, ...}:

{
  # Builder for a macOS system.
  mkDarwin = { hostname, system, user }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;

      modules = [
        ({pkgs, ...}: {
          imports = [ <home-manager/nix-darwin>  ];

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
            users.${user} = import ../macos/home.nix {
              inherit pkgs;
              enableNixpkgsReleaseCheck = false;
              stateVersion = "23.11";
            };
          };
        })
      ];
    };
}