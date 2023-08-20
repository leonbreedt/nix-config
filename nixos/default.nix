{ lib, config, inputs, pkgs, stable, hostname, secrets, user, machineConfig, ... }:

let 
  keys = [
    # public key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCz89QU2uyL7hhfgVPP6l9XFBViQBk2zMpD06MZicl/0BJnlJTfqOWEIcU37NbEME0gbJpan7OEdrwr3xDevsx+mCCzARDDotKzE27/mrPkjVosaM0jxqxBOWvGRGr/l2rbmXyKGP4G21QHcwNk5KWKgOCcp4MhxH5Gpb4xA7JITuB5rH+83PF9nmsSELQpo9zKpJYhOO8O1cKUOMkdvB73hpe28vMRfaEouc2ElsiVhT+hEU/Pux3bxCvy+vHAMlA3xBW6BKb442EvCo0+ulhtILvPjjjMCOYE7bTjRbTltkpMD/pTeWB5kbMd/+Grrt393VspYnLCmUCoNAKfSqdsf5WSx+sBF5HRzikboe0oz6ejRnbjcA5vVyTGID/xZwg0xwUqFaBF+PdCDyk2SX29T2WKu6ewDLl25uv085h332xfb40qTlf6OQysQsiC5boImzMdVhbWl9dLNvd0XSR36iF1iieJE+3W+v9grHqD6IUkdt/kDiTqWsfgTSyVutM="
  ];
in
{
  imports = [
    ../common
  ];

  # Use unstable Nix so we can use flakes.
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.allowed-users = [ "${user}" ];
  };
 
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = !machineConfig.isWSL;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "Pacific/Auckland";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  networking.hostName = hostname;
  networking.useDHCP = false;

  # IPv6, yech.
  networking.enableIPv6 = false;

  programs.gnupg.agent.enable = true;

  # Needed for anything GTK related
  programs.dconf.enable = machineConfig.isDesktop;

  # Needed both here and in home-manager.
  programs.fish.enable = true;

  # Local mail (e.g. cron jobs)
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
      user = builtins.readFile "${secrets}/smtp-user";
      password = builtins.readFile "${secrets}/smtp-password";
    };
  };
  environment.etc = {
    "aliases" = {
      text = ''
        root: leon@sector42.io
        leon: leon@sector42.io
        unifi: leon@sector42.io
      '';
      mode = "0644";
    };
  };


  services.xserver.enable = machineConfig.isDesktop;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  services.xserver.displayManager.defaultSession = "none+bspwm";
  services.xserver.displayManager.lightdm = {
    enable = machineConfig.isDesktop;
    greeters.slick.enable = machineConfig.isDesktop;
    background = ../common/config/color-wave-1.jpg;
  };

  services.xserver.windowManager.bspwm = {
    enable = machineConfig.isDesktop;
  };

  sound.enable = machineConfig.isDesktop;
  hardware.pulseaudio.enable = machineConfig.isDesktop;

  hardware.opengl.enable = machineConfig.isDesktop;
  hardware.opengl.driSupport32Bit = machineConfig.isDesktop;
  hardware.opengl.driSupport = machineConfig.isDesktop;
  hardware.nvidia.modesetting.enable = machineConfig.isDesktop;

  # Better support for general peripherals
  services.xserver.libinput = {
    enable = machineConfig.isDesktop;
    # macOS for lyfe
    touchpad.naturalScrolling = true;
  };

  # Support Docker
  virtualisation.docker = {
    enable = machineConfig.enableDocker;
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
    openssh.authorizedKeys.keys = keys;
  };

  environment.systemPackages = with pkgs; [
    inetutils
    moreutils
    tarsnap
    ssl-cert-check
  ];

  services.unifi = {
    enable = machineConfig.isUnifiController;
    unifiPackage = pkgs.unifi7;
    mongodbPackage = stable.mongodb-4_2;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]
      ++ lib.optionals machineConfig.isUnifiController [ 8080 8443 8880 8843 ]
      ++ lib.optionals machineConfig.enableDocker [ 2375 ];
    allowedUDPPorts = [] ++ lib.optionals machineConfig.isUnifiController [ 3478 10001 ];
  };
  networking.nat = {
    enable = machineConfig.isUnifiController;
    externalInterface = (builtins.readFile "${secrets}/personal-controller-external-interface");
    internalIPs = [ (builtins.readFile "${secrets}/lan-cidr") ];
    forwardPorts = [
      { destination = (builtins.readFile "${secrets}/unifi-controller-ip") + ":8443"; sourcePort = 443; }
    ];
  };

  services.cron = {
    enable = machineConfig.shouldBackupWithTarsnap;
    systemCronJobs = [
      ''
        1 3 * * * root ${pkgs.moreutils}/bin/chronic ${pkgs.writeTextFile {
          name = "tarsnap-backup.sh";
          text = ''
${pkgs.tarsnap}/bin/tarsnap \
  -c \
  --keyfile ${pkgs.tarsnap-key}/tarsnap.key \
  --cachedir /var/cache/tarsnap \
  -f "$(uname -n)-$(date +%Y-%m-%d_%H-%M-%S)" \
  ${lib.concatStringsSep " \\\n" machineConfig.tarsnapDirectories}
'';
          executable = true;
        }} && ${pkgs.curl}/bin/curl -s -m 10 --retry 5 https://hc-ping.com/${machineConfig.tarsnapHealthCheckUUID} >/dev/null
      ''
    ] ++ lib.optionals machineConfig.isUnifiController [
      ''
        1 4 * * * root ${pkgs.moreutils}/bin/chronic ${pkgs.ssl-cert-check}/bin/ssl-cert-check -s sector42.io -p 443 -n && ${pkgs.curl}/bin/curl -s -m 10 --retry 5 https://hc-ping.com/5629ec4f-d2b8-43e6-8328-9f43d1e10464 >/dev/null
      ''
      ''
        1 4 * * * root ${pkgs.moreutils}/bin/chronic ${pkgs.ssl-cert-check}/bin/ssl-cert-check -s leonbreedt.com -p 443 -n && ${pkgs.curl}/bin/curl -s -m 10 --retry 5 https://hc-ping.com/cd36f383-a2b0-4eb9-a2b9-2a4c082f1fee >/dev/null
      ''
    ];
  };

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; lib.optionals machineConfig.isDesktop [
      (iosevka.override {
        privateBuildPlan = builtins.readFile ../common/config/iosevka-lb;
        set = "lb";
      })
    ];
  };


  system.stateVersion = "23.11"; # Don't change this
}
