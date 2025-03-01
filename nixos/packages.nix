# nixOS-specific packages
{ pkgs, config, ... }:

with pkgs; [
] ++ lib.optionals config.machine.gui.enabled [
  feh
  scrot
  ucs-fonts
  sf-pro
  overpass
  google-chrome
  firefox
  zed-editor
] ++ lib.optionals (config.machine.gui.environment == "gnome") [
  gnome.gnome-tweaks
  gnome.epiphany
  gnome.yelp
  gnome.cheese
]
