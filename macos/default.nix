# macOS-specific configuration

{ ... }:

{
  # Enable the Nix daemon for maintenance activities.
  services.nix-daemon.enable = true;

  # Disable NIX_PATH validation checks, we are using flakes.
  system.checks.verifyNixPath = false;
}
