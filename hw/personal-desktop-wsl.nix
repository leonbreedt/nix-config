{ config, lib, pkgs, modulesPath, ... }:

{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
