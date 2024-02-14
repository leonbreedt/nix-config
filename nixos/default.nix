{ pkgs, lib, secrets, isPersonal, isDesktop, isWSL, enableDocker, user, hostname, ... }:

{
  # Use unstable Nix so we can use flakes.
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.allowed-users = [ user ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = !isWSL;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kia ora
  time.timeZone = "Pacific/Auckland";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  networking.hostName = hostname;
  networking.useDHCP = false;

  # IPv6, yech.
  networking.enableIPv6 = false;

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]
      ++ lib.optionals isUnifiController [ 8080 8443 8880 8843 ]
      ++ lib.optionals enableDocker [ 2375 ];
    allowedUDPPorts = [] ++ lib.optionals isUnifiController [ 3478 10001 ];
  };

  # NAT
  networking.nat = {
    enable = isUnifiController;
    externalInterface = (builtins.readFile secrets.personal-controller-external-interface);
    internalIPs = [ (builtins.readFile secrets.lan-cidr ];
    forwardPorts = [
      { destination = (builtins.readFile "${secrets.unifi-controller-ip}") + ":8443"; sourcePort = 443; }
    ];
  };

  programs = {
    gnupg.agent.enable = true;
    dconf.enable = true;
    # Needed both here and in home-manager.
    fish.enable = true;
  };

  # Make local mail work (e.g. cron jobs)
  programs.msmtp = {
    enable = true;
    defaults = {
      aliases = "/etc/aliases";
    };
    accounts.default = {
      from = "noreply@sector42.io";
      auth = true;
      tls = true;
      host = "smtp.gmail.com";
      port = "587";
      syslog = true;
      user = builtins.readFile secrets.smtp-user;
      password = builtins.readFile secrets.smtp-password;
    };
  };

  environment.etc = {
    "aliases" = {
      text = ''
        root: ${secrets.smtp-user}
        ${user}: ${secrets.smtp-user}
        unifi: ${secrets.smtp-user}
      '';
      mode = "0644";
    };
  };

  environment.systemPackages = with pkgs; [
    inetutils
    moreutils
    tarsnap
    ssl-cert-check
  ];

  services = {
    xserver = {
      enable = isDesktop;

      displayManager.defaultSession = "none+bspwm";
      displayManager.lightdm = {
        enable = isDesktop;
        greeters.slick.enable = isDesktop;
        # background = ../common/config/color-wave-1.jpg;
      };

      windowManager.bspwm.enable = isDesktop;

      libinput = {
        enable = machineConfig.isDesktop;
        # macOS for lyfe
        touchpad.naturalScrolling = true;
      };
    };

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    unifi = {
      enable = isUnifiController;
      unifiPackage = pkgs.unifi7;
      mongodbPackage = stable.mongodb-4_2;
    };
  };

  sound.enable = isDesktop;
  hardware.pulseaudio.enable = isDesktop;
  hardware.opengl.enable = isDesktop;
  hardware.opengl.driSupport32Bit = isDesktop;
  hardware.opengl.driSupport = isDesktop;
  hardware.nvidia.modesetting.enable = isDesktop;

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; isDesktop [
      coding-fonts
      sf-mono
      geist-mono
      intel-one-mono
      (iosevka.override {
        privateBuildPlan = builtins.readFile ../common/config/iosevka-lb;
        set = "lb";
      })
    ];
  };

  virtualisation.docker = {
    enable = enableDocker;
    listenOptions = [
      "0.0.0.0:2375"
      "/run/docker.sock"
    ];
    logDriver = "json-file";
  };

  # It's me
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      builtins.readFile secrets.ssh-authorized-key
    ];
  };

  system.stateVersion = "23.11"; # Don't change this
}
