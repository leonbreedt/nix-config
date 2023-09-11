# Common configuration across systems

{ pkgs, hostname, ... }:

{
  nix = {
    # Use latest 'nix' CLI
    package = pkgs.nixUnstable;

    # Don't require --extra-experimental-features every time we
    # want to use 'nix flake'
    extraOptions = "experimental-features = nix-command flakes";
  };

  # Ensure hostname is set system-wide.
  networking.hostName = "${hostname}";

  environment = {
    # Install common packages globally
    systemPackages = import ./packages.nix { inherit pkgs; };

    # Make Fish shell available in /etc/shells
    shells = [ pkgs.fish ];
  };
}
