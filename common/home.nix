# Common Home Manager configuration
{ pkgs }:

{
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
}
