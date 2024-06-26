# Dock icons
{pkgs, lib, isPersonal}:

[
  { path = "${pkgs.wezterm}/Applications/WezTerm.app/"; }
] ++ lib.optionals (!isPersonal) [
  { path = "/Applications/Google Chrome.app/"; }
] ++ lib.optionals isPersonal [
  { path = "/Applications/Brave Browser.app/"; }
  { path = "/System/Applications/Messages.app/"; }
  { path = "/System/Applications/Photos.app/"; }
  { path = "/Applications/Mimestream.app/"; }
]
