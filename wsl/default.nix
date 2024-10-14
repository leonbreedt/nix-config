# WSL-specific configuration

{ lib, pkgs, user, ... }:

{
  # Enable WSL support.
  wsl = {
    enable = true;
    defaultUser = "${user}";

    # Use native systemd support.
    nativeSystemd = true;
  };
}
