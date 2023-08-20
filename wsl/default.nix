{
  pkgs,
  user,
  ...
}: {
  wsl = {
    enable = true;
    defaultUser = "${user}";
    startMenuLaunchers = true;
    nativeSystemd = true;

    # Enable native Docker support
    docker-native.enable = true;
  };

  system.stateVersion = "23.11";
}
