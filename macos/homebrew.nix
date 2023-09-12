# Homebrew configuration for apps not available in nixpkgs.
{lib, isPersonal}:

{
  enable = true;

  onActivation = {
    autoUpdate = true;
    cleanup = "zap";
    upgrade = true;
  };

  casks = [
    "brave-browser"
    "google-chrome"
    "jetbrains-toolbox"
    "postico"
    "postgres-unofficial"
    "zoom"
  ] ++ lib.optionals isPersonal [
    "mimestream"
    "vlc"
    "transmission"    
  ] ++ lib.optionals (!isPersonal) [
    "postman"
  ];

  masApps = {};
}

