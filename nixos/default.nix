{ pkgs, lib, config, secrets, ... }:

let
  isEdgeRouter = config.machine.kind == "edge-router";
  isDevelopmentMachine = config.machine.kind == "development-machine";
  isUnifiController = config.machine.kind == "unifi-controller";
  isDockerEnabled = isDevelopmentMachine;
  isPersonal = config.machine.personal;
  useX11 = config.machine.gui.enabled;
  useBspwm = useX11 && config.machine.gui.environment == "bspwm";
  useGnome = useX11 && config.machine.gui.environment == "gnome";
in
{
  # Networking

  networking = {
    enableIPv6 = false;
    firewall = {
      enable = isEdgeRouter;
      allowedTCPPorts = [ 22 ] ++ lib.optionals isDockerEnabled [ 2375 ];
    };
    nat = {
      enable = isEdgeRouter;
    };
  };

  # Base programs

  programs = {
    gnupg.agent.enable = true;
    fish.enable = true;
    msmtp = {
      enable = true;
      defaults = {
        aliases = "/etc/aliases";
      };
      accounts = {
        default = {
          from = "noreply@sector42.io";
          auth = true;
          tls = true;
          host = "smtp.gmail.com";
          port = "587";
          syslog = true;
          user = secrets.smtp-user;
          password = secrets.smtp-password;
        };
      };
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

  # Services

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  services.unifi = {
    enable = isUnifiController;
    unifiPackage = pkgs.unifi8;
  };

  services.unbound = {
    enable = isEdgeRouter;
    settings = {
      server = {
        interface = [ "0.0.0.0" ];
        access-control = [ "127.0.0.1 allow" "192.168.1.0/24 allow" ];
        use-syslog = true;
        # https://unbound.docs.nlnetlabs.nl/en/latest/topics/core/performance.html
        num-threads = 4;
        msg-cache-slabs = 4;
        rrset-cache-slabs = 4;
        infra-cache-slabs = 4;
        key-cache-slabs = 4;
        # rrset=msg*2
        rrset-cache-size = "200m";
        msg-cache-size = "100m";
        so-rcvbuf = "2m";
        so-sndbuf = "2m";
        # 1024/ncores - 50
        outgoing-range = 200;
        # outgoing-range/2
        num-queries-per-thread = 100;
      };
      auth-zone = [
        {
          name = "home";
          for-downstream = true;
          for-upstream = true;
          zonefile = ''${pkgs.writeTextFile {
            name = "home.zone";
            text = builtins.readFile ./config/home.zone;
          }}
          '';
        }
      ];
      forward-zone = [
        {
          name = ".";
          forward-addr = [ "122.56.237.1" "210.55.111.1" ]; # Spark NZ
        }
      ];
    };
  };

  services.cron = {
    enable = true;

    systemCronJobs = 
      lib.optionals config.machine.tarsnap.enabled [
        ''
          0 2 * * * root ${pkgs.moreutils}/bin/chronic ${pkgs.writeTextFile {
            name = "tarsnap-backup.sh";
            executable = true;
            text = ''
${pkgs.tarsnap}/bin/tarsnap \
  -c \
  --keyfile ${pkgs.writeTextFile {
    name = "tarsnap.key";
    executable = false;
    text = config.machine.tarsnap.key;
  }} \
  --cachedir /var/cache/tarsnap \
  -f "$(uname -n)-$(date +%Y-%m-%d_%H-%M-%S)" \
  ${lib.concatStringsSep " \\\n" config.machine.tarsnap.dirs}
'';
          }} && ${pkgs.curl}/bin/curl -s -m 10 --retry 5 https://hc-ping.com/${config.machine.tarsnap.healthcheck} >/dev/null
        ''
      ] ++ lib.optionals isUnifiController [
        ''
          0 2 * * * root ${pkgs.moreutils}/bin/chronic ${pkgs.ssl-cert-check}/bin/ssl-cert-check -s sector42.io -p 443 -n && ${pkgs.curl}/bin/curl -s -m 10 --retry 5 https://hc-ping.com/5629ec4f-d2b8-43e6-8328-9f43d1e10464 >/dev/null
        ''
        ''
          0 2 * * * root ${pkgs.moreutils}/bin/chronic ${pkgs.ssl-cert-check}/bin/ssl-cert-check -s leonbreedt.com -p 443 -n && ${pkgs.curl}/bin/curl -s -m 10 --retry 5 https://hc-ping.com/cd36f383-a2b0-4eb9-a2b9-2a4c082f1fee >/dev/null
        ''
      ];
  };

  virtualisation.docker = {
    enable = isDevelopmentMachine;
    listenOptions = [
      "0.0.0.0:2375"
      "/run/docker.sock"
    ];
    logDriver = "json-file";
  };

  # GUI
  services.xserver.enable = useX11;

  fonts = {
    fontDir.enable = useX11;
    packages = with pkgs; lib.optionals useX11 [
      coding-fonts
      sf-mono
      sf-pro
      geist-mono
      intel-one-mono
      overpass
      (iosevka.override {
        privateBuildPlan = builtins.readFile ../common/config/iosevka-lb;
        set = "lb";
      })
    ];
  };

  services.xserver.displayManager.gdm = {
    enable = useGnome;
    # use Xorg, not Wayland
    wayland = false;
    settings.daemon.DefaultSession = "gnome-xorg.desktop";
  };
  services.xserver.desktopManager.gnome.enable = useGnome;
  programs.dconf.enable = useGnome;

  services.xserver.displayManager.lightdm = {
    enable = useBspwm;
    greeters.slick = {
      enable = useBspwm;
      font.name = "IosevkaLB 12";
      cursorTheme.size = 48;
      extraConfig = ''
        xft-dpi=192
        enable-hidpi=on
      '';
    };
    background = ../common/config/wallpaper/color-wave-1.jpg;
  };

  services.xserver.windowManager.bspwm = {
    enable = useBspwm;
  };

  services.libinput = {
    enable = useX11;
    touchpad.naturalScrolling = true;
  };

  programs.steam.enable = useX11 && isPersonal;

  system.stateVersion = "24.11";
}
