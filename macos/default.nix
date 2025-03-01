# macOS-specific configuration

{ pkgs, lib, secrets, isPersonal, ... }:

{
  # Enable the Nix daemon for maintenance activities.
  services.nix-daemon.enable = true;
  nix.settings.allow-users = [ config.machine.user ];

  # Enable Redis on work machines.
  services.redis.enable = !isPersonal;

  # Disable NIX_PATH validation checks, we are using flakes.
  system.checks.verifyNixPath = false;

  # MacOS preferences.
  system.defaults = import ./preferences.nix;

  # Packages from Homebrew
  homebrew = import ./homebrew.nix { inherit lib isPersonal; };

  # Dock configuration
  local.dock = {
    enable = true;
    entries = import ./dock.nix { inherit pkgs lib isPersonal; };
  };

  # CA certificates
  security.pki.certificates = [
    (builtins.readFile ../common/config/sector42-ca.pem)
    secrets.work-root-ca-01-crt
    secrets.work-root-ca-02-crt
  ];

  # Install fonts in font directory.
  # Font configuration uses different attributes on macOS ('fonts' instead of 'packages').
  fonts = {
    packages = with pkgs; [
      coding-fonts
      sf-mono
      geist-mono
      intel-one-mono
      (iosevka.override {
        privateBuildPlan = builtins.readFile ../common/config/iosevka-lb;
        set = "lb";
      })
    ];
  };

  system.stateVersion = 5;
}
