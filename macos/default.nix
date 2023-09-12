# macOS-specific configuration

{ pkgs, ... }:

{
  # Enable the Nix daemon for maintenance activities.
  services.nix-daemon.enable = true;

  # Disable NIX_PATH validation checks, we are using flakes.
  system.checks.verifyNixPath = false;

  # MacOS preferences.
  system.defaults = import ./preferences.nix;

  # Install fonts in font directory.
  # Font configuration uses different attributes on macOS ('fonts' instead of 'packages').
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      (iosevka.override {
        privateBuildPlan = builtins.readFile ../common/config/iosevka-lb;
        set = "lb";
      })
    ];
  };
}
