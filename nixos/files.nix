# nixOS-specific managed home directory files
{ config, lib, ... }:

{
} // lib.optionalAttrs config.machine.gui.enabled {
  ".wallpaper".source = ../common/config/wallpaper/color-wave-1.jpg;
}
