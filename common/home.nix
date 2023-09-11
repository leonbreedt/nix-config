# Common Home Manager configuration
{ pkgs, ... }:

{
  home = {
    stateVersion = "23.11";

    sessionVariables = {
      TERM = "xterm-256color";
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = "nvim";
      PAGER = "bat -p";
      MANPAGER = "bat -p";
    };
  };

  # Set up Home Manager programs (independent of nix-darwin programs!)
  programs = {
    # Shell
    fish = {
      enable = true;
      shellInit = ''
        if test -d $HOME/.cargo/bin
          fish_add_path $HOME/.cargo/bin
        end
        if test -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
          fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
        end
        if test -d "/Applications/Postgres.app/Contents/Versions/latest/bin"
          fish_add_path "/Applications/Postgres.app/Contents/Versions/latest/bin"
        end

        set -gx CDPATH . $HOME/Source $HOME/source

        alias kc kubectl
        alias cat "bat -p"
        alias less "bat -p"
        alias ls "eza"
        '';
    };
  };
}
