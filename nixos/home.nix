# nixOS-specific user configuration
{ config, lib, ... }:

let
  useBspwm = config.machine.gui.enabled && config.machine.environment == "bspwm"; 
  useGnome = config.machine.gui.enabled && config.machine.environment == "gnome";
in
{
  xsession.windowManager.bspwm = {
    enable = useBspwm;
    monitors = {
      "DP-2" = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" ];
    };
    alwaysResetDesktops = true;
    settings = {
      border_width = 4;
      border_radius = 10;
      focused_border_color = "#8fbcbb";
      active_border_color = "#2e3440";
      normal_border_color = "#2e3440";
      top_padding = 60;
      window_gap = 20;
      borderless_monocle = true;
      gapless_monocle = false;
      split_ratio = 0.52;
      focus_follows_pointer = true;
    };
    extraConfig = ''
      feh --bg-scale ~/.wallpaper
    '';
  };

  # compositor
  services.picom = {
    enable = useBspwm;
    shadow = true;

    settings = {
      "shadow-radius" = 15;
      "corner-radius" = 10;
      #"rounded-corners-exclude" = ["! class_g = 'Polybar' && ! class_g = 'Rofi'"];
    };
  };

  # utility toolbars
  services.polybar = {
    enable = useBspwm;
    config = ./config/polybar;
    script = ''
      polybar desktop &
      polybar status &
      polybar title &
    '';
  };
  systemd.user.services.polybar.Install.WantedBy = [ "graphical-session.target" "tray.target" ];

  # rofi
  programs.rofi = {
    enable = useBspwm;
    font = "IosevkaLB 12";
    theme = "paper-float";
  };

  # keyboard shortcuts
  services.sxhkd = {
    enable = useBspwm;
    keybindings = {
      "super + Return" = "wezterm";
      "super + @space" = "rofi -show run";
      "super + shift + q" = "bspc quit";

      # focus node in direction
      "super + {_,shift + }{Left,Down,Up,Right}" = "bspc node -{f,s} {west,south,north,east} --follow";

      # move window between monitors
      "super + alt + {Left,Right}" = "bspc node -m {prev,next} --follow";

      # switch desktops
      "super + 1" = "bspc desktop -f 1";
      "super + 2" = "bspc desktop -f 2";
      "super + 3" = "bspc desktop -f 3";
      "super + 4" = "bspc desktop -f 4";
      "super + 5" = "bspc desktop -f 5";
      "super + 6" = "bspc desktop -f 6";
      "super + 7" = "bspc desktop -f 7";
      "super + 8" = "bspc desktop -f 8";
      "super + 9" = "bspc desktop -f 9";

      # move node to desktop
      "super + shift + 1" = "bspc node -d 1";
      "super + shift + 2" = "bspc node -d 2";
      "super + shift + 3" = "bspc node -d 3";
      "super + shift + 4" = "bspc node -d 4";
      "super + shift + 5" = "bspc node -d 5";
      "super + shift + 6" = "bspc node -d 6";
      "super + shift + 7" = "bspc node -d 7";
      "super + shift + 8" = "bspc node -d 8";
      "super + shift + 9" = "bspc node -d 9";
    };
  };

  # desktop setup
  xresources.extraConfig = ''
    ${builtins.readFile ./config/Xresources}

    ! monitor names used in configuration
    *monitor1: DP-2
  '';

  # custom XDG dir names
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      desktop = "$HOME/desktop";
      download = "$HOME/downloads";
      documents = "$HOME/documents";
      templates = "$HOME/templates";
      music = "$HOME/music";
      videos = "$HOME/videos";
      pictures = "$HOME/pictures";
      publicShare = "$HOME/public";
    };
  };

  # DConf settings
  dconf.settings = lib.optionalAttrs useGnome {
    "org/gnome/desktop/interface" = {
      font-name = "Overpass Semi-Bold 10";
      font-hinting = "medium";
      font-antialiasing = "rgba";
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file://${config.machine.homedir}/.wallpaper";
      picture-uri-dark = "file://${config.machine.homedir}/.wallpaper";
    };
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];
    };
  };
}
