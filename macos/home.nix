# macOS-specific Home Manager configuration
{ pkgs, ... }:

let
  common-home = import ../common/home.nix { inherit pkgs; };
in
{
  home = common-home // {
    # TODO
  };
}
