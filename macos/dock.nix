# Dock icons
{pkgs, lib, isPersonal}:

[
  { path = "/System/Cryptexes/App/System/Applications/Safari.app/"; }
  { path = "${pkgs.wezterm}/Applications/WezTerm.app/"; }
] ++ lib.optionals isPersonal [
  { path = "/System/Applications/Messages.app/"; }
  { path = "/System/Applications/Photos.app/"; }
  { path = "/Applications/Mimestream.app/"; }
]
