{ pkgs, hostname, ... }:

{
  services.nix-daemon.enable = true;
  networking.hostName = "${hostname}";
  environment.shells = [ pkgs.fish ];
}
