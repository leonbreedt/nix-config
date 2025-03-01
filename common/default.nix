# Common configuration across systems

{ pkgs, config, ... }:

{
  nix = {
    # Don't require --extra-experimental-features every time we
    # want to use 'nix flake'
    extraOptions = "experimental-features = nix-command flakes";
    settings = {
      trusted-users = [ "root" config.machine.user ];
    };
  };

  # Cross-platform networking configuration.
  networking = {
    hostName = config.machine.hostname;
  };

  environment = {
    # Make Fish shell available in /etc/shells
    shells = [ pkgs.fish ];
  };

  # Always allow unfree packages.
  nixpkgs.config.allowUnfree = true;
}
