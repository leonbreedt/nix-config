# MacOS system preferences
# Reference: https://daiderd.com/nix-darwin/manual/index.htm

{
  LaunchServices = {
    LSQuarantine = false;
  };

  NSGlobalDomain = {
    AppleShowAllExtensions = true;
    ApplePressAndHoldEnabled = false;
    AppleInterfaceStyle = "Dark";

    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;

    # Use F1, F2, etc as function keys.
    "com.apple.keyboard.fnState" = true;

    # Expand save panels by default.
    NSNavPanelExpandedStateForSaveMode = true;
    NSNavPanelExpandedStateForSaveMode2 = true;
  };

  CustomUserPreferences = {
    "com.apple.finder" = {
      # Set user home dir as default Finder dir
      NewWindowTarget = "PfHm";
    };
  };

  finder = {
    # List view
    FXPreferredViewStyle = "Nlsv";

    # Search current folder, not Mac.
    FXDefaultSearchScope = "SCcf";
  };

  dock = {
    autohide = false;
    show-recents = false;
    launchanim = true;
    mineffect = "scale";
    orientation = "left";
    tilesize = 48;
  };
}
