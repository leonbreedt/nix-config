{
  description = "NixOS and MacOS configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/master";
    };
    stable-nixos = {
      url = "github:NixOS/nixpkgs/nixos-23.05";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/leonbreedt/private.git";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, stable-nixos, home-manager, darwin, nixos-wsl, secrets, ... }@inputs: 
  let
    pkgConfig = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    }; 
    defaultMachineConfig = {
      isPersonal = true;
      isDesktop = false;
      isWSL = false;
      enableDocker = false;
      isUnifiController = false;
      shouldBackupWithTarsnap = false;
      tarsnapDirectories = [ "/etc" "/root" ];
      tarsnapHealthCheckUUID = "";
    };
    stable = import inputs.stable-nixos {
      system = "x86_64-linux";
      config = pkgConfig;
    };
    hosts = {
      personal = {
        laptop = builtins.readFile "${secrets}/personal-laptop-host";
        desktop = builtins.readFile "${secrets}/personal-desktop-host";
        controller = builtins.readFile "${secrets}/personal-controller-host";
      };
      work = {
        laptop = builtins.readFile "${secrets}/work-laptop-host";
      };
    };
    users = {
      personal = builtins.readFile "${secrets}/personal-user";
      work = builtins.readFile "${secrets}/work-user";
    };
    overlay-jdk17 = final: prev: {
      # Force packages with Java dependencies to use 17 (e.g. Maven)
      jdk = prev.jdk17;
      jre = prev.jre17_minimal;
    };
  in
  {
    darwinConfigurations = {
      # Personal MacBook Pro 16"
      "${hosts.personal.laptop}" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ({ pkgs, ... }: { nixpkgs.overlays = [ overlay-jdk17 ]; })
          ./macos
        ];
        inputs = { inherit darwin home-manager nixpkgs secrets; };
        specialArgs = {
          secrets = secrets;
          user = users.personal;
          hostname = hosts.personal.laptop;
          machineConfig = defaultMachineConfig;
        };
      };

      # Work MacBook Pro 16"
      "${hosts.work.laptop}" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ({ pkgs, ... }: { nixpkgs.overlays = [ overlay-jdk17 ]; })
          ./macos
        ];
        inputs = { inherit darwin home-manager nixpkgs secrets; };
        specialArgs = {
          secrets = secrets;
          user = users.work; 
          hostname = hosts.work.laptop;
          machineConfig = defaultMachineConfig // { isPersonal = false; };
        };
      };
    };

    nixosConfigurations = {
      # Ryzen 3900X desktop - Linux
      "${hosts.personal.desktop}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: { nixpkgs.overlays = [
            overlay-jdk17
            (final: prev: {
              tarsnap-key = final.callPackage ./packages/tarsnap-key.nix {
                secrets = secrets;
                hostname = hosts.personal.desktop;
              };
            })
          ]; })
          ./nixos
          ./hw/personal-desktop.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."${users.personal}" = import ./nixos/home-manager.nix;
            home-manager.extraSpecialArgs = {
              secrets = secrets;
              user = users.personal; 
              hostname = hosts.personal.desktop; 
              stable = stable;
              machineConfig = defaultMachineConfig // {
                isDesktop = true;
                enableDocker = true;
                shouldBackupWithTarsnap = true;
                tarsnapHealthCheckUUID = (builtins.readFile "${secrets}/personal-desktop-tarsnap-hc-uuid");
              };
            };
          }
        ];
        specialArgs = {
          secrets = secrets;
          user = users.personal; 
          hostname = hosts.personal.desktop; 
          stable = stable;
          machineConfig = defaultMachineConfig // {
            isDesktop = true;
            enableDocker = true;
            shouldBackupWithTarsnap = true;
            tarsnapHealthCheckUUID = (builtins.readFile "${secrets}/personal-desktop-tarsnap-hc-uuid");
          };
        };
      };

      # Ryzen 3900X desktop - WSL
      "${hosts.personal.desktop}-wsl" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: { nixpkgs.overlays = [
            overlay-jdk17
            (final: prev: {
              tarsnap-key = final.callPackage ./packages/tarsnap-key.nix {
                secrets = secrets;
                hostname = hosts.personal.desktop;
              };
            })
          ]; })
          ./nixos
          ./hw/personal-desktop-wsl.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."${users.personal}" = import ./nixos/home-manager.nix;
            home-manager.extraSpecialArgs = {
              secrets = secrets;
              user = users.personal; 
              hostname = hosts.personal.desktop; 
              stable = stable;
              machineConfig = defaultMachineConfig // {
                isDesktop = true;
                enableDocker = true;
                isWSL = true;
              };
            };
          }
          ./wsl
          inputs.nixos-wsl.nixosModules.wsl
        ];
        specialArgs = {
          secrets = secrets;
          user = users.personal; 
          hostname = hosts.personal.desktop; 
          stable = stable;
          machineConfig = defaultMachineConfig // {
            isDesktop = true;
            enableDocker = true;
            isWSL = true;
          };
        };
      };

      # Intel NUC
      "${hosts.personal.controller}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: { nixpkgs.overlays = [
            overlay-jdk17
            (final: prev: {
              tarsnap-key = final.callPackage ./packages/tarsnap-key.nix {
                secrets = secrets;
                hostname = (builtins.readFile "${secrets}/personal-controller-host");
              };
            })
          ]; })
          ./nixos
          ./hw/personal-controller.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."${users.personal}" = import ./nixos/home-manager.nix;
            home-manager.extraSpecialArgs = {
              secrets = secrets;
              user = users.personal;
              hostname = hosts.personal.controller;
              stable = stable;
              machineConfig = defaultMachineConfig // {
                isUnifiController = true;
                shouldBackupWithTarsnap = true;
                tarsnapDirectories = [ "/etc" "/root" "/var/lib/unifi" ];
                tarsnapHealthCheckUUID = (builtins.readFile "${secrets}/personal-controller-tarsnap-hc-uuid");
              };
            };
          }
        ];
        specialArgs = {
          secrets = secrets;
          user = users.personal;
          hostname = hosts.personal.controller;
          stable = stable;
          machineConfig = defaultMachineConfig // {
            isUnifiController = true;
            shouldBackupWithTarsnap = true;
            tarsnapDirectories = [ "/etc" "/root" "/var/lib/unifi" ];
            tarsnapHealthCheckUUID = (builtins.readFile "${secrets}/personal-controller-tarsnap-hc-uuid");
          };
        };
      };
    };
  };
}
