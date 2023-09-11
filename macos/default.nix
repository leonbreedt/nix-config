{ hostname, ... }:

{
  services.nix-daemon.enable = true;
  networking.hostName = "${hostname}";
}
