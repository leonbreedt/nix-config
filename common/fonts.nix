# System font configuration
{ pkgs, ... }:

{
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      (iosevka.override {
        privateBuildPlan = builtins.readFile ./config/iosevka-lb;
        set = "lb";
      })
    ];
  };
}
