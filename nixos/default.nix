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
  # Time

  time.timeZone = lib.mkDefault "Pacific/Auckland";

  # Networking

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = isEdgeRouter;
  };

  networking = {
    enableIPv6 = false;
    firewall = {
      enable = isEdgeRouter;
      allowedTCPPorts = [ 22 53 ];
      allowedUDPPorts = [ 53 ];
    };
    nat.enable = true;
    nftables.enable = true;
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

  services.ntp = {
    enable = true;
  };

  services.unifi = {
    enable = isUnifiController;
    unifiPackage = pkgs.unifi8;
  };

  services.pppd = {
    enable = true;
    peers = {
      spark = {
        autostart = true;
        enable = true;
        config = ''
          plugin pppoe.so wan

          user "${secrets.ppp-username}"
          password "${secrets.ppp-password}"

          persist
          maxfail 0
          holdoff 5

          mtu 1492

          noipdefault
          noipv6
          defaultroute
        '';
      };
    };
  };

  services.kea.dhcp4 = {
    enable = isEdgeRouter;
    settings = {
      interfaces-config = {
        interfaces = [ "enp86s0" ];
      };

      renew-timer = 86400;
      rebind-timer = 1800;
      valid-lifetime = 86400;

      option-data = [
        {
          name = "routers";
          data = "192.168.1.1";
        }
        {
          name = "domain-name-servers";
          data = "192.168.1.1";
        }
        {
          name = "domain-name";
          data = "home";
        }
        {
          name = "domain-search";
          data = "home";
        }
      ];

      subnet4 = [
        {
          id = 1;
          subnet = "192.168.1.0/24";
          pools = [
            {
              pool = "192.168.1.160-192.168.1.250";
            }
          ];
          reservations = [
						# CORE INFRASTRUCTURE
						{
							# Infra: Intel NUC
							hw-address = "b8:ae:ed:71:33:84";
							ip-address = "192.168.1.1";
							hostname = "gateway";
						}
						{
							# Infra: Office AP
							hw-address = "80:2a:a8:c0:88:e7";
							ip-address = "192.168.1.2";
							hostname = "office-ap";
						}
						{
							# Infra: Lounge AP
							hw-address = "80:2a:a8:c3:d1:72";
							ip-address = "192.168.1.3";
							hostname = "lounge-ap";
						}
						{
							# Infra: TrueNAS
							hw-address = "3c:ec:ef:fa:66:26";
							ip-address = "192.168.1.4";
							hostname = "nas";
						}
						{
							# Infra: Unifi Controller
							hw-address = "48:21:b:6a:b5:ee";
							ip-address = "192.168.1.5";
							hostname = "unifi-controller";
						}
						{
							# Infra: TP-Link PoE switch
							hw-address = "50:d4:f7:00:44:35";
							ip-address = "192.168.1.6";
							hostname = "tp-link-poe-switch";
						}
						{
							# Infra: CalDigit TS4 Dock (Ethernet)
							hw-address = "64:4b:f0:37:3a:32";
							ip-address = "192.168.1.7";
							hostname = "dock-ethernet";
						}

						# SERVICES
				 
						# Service IPs are not provided via DHCP on TrueNAS SCALE, they are all
						# statically configured on the NAS interface, since they are not running in Jails
						# with custom MAC addresses.

						# MACHINES

						{
							# Machine: Leon's Desktop
							hw-address = "58:11:22:cf:0c:a3";
							ip-address = "192.168.1.50";
							hostname = "leon-desktop";
						}
						{
							# Machine: Leon's MacBook Pro (WiFi)
							hw-address = "6e:fe:5d:db:c7:ae";
							ip-address = "192.168.1.51";
							hostname = "leon-mbp";
						}
						{
							# Machine: Work MacBook Pro (WiFi)
							hw-address = "3a:20:4c:f3:c1:5c";
							ip-address = "192.168.1.52";
							hostname = "leon-desktop";
						}
						{
							# Machine: Chanthaly's MacBook Air
							hw-address = "f2:64:d8:14:5d:41";
							ip-address = "192.168.1.53";
							hostname = "chanthaly-mba";
						}

						# MOBILE DEVICES

						{
							# Mobile: Leon's iPhone
							hw-address = "ee:de:81:78:13:74";
							ip-address = "192.168.1.100";
							hostname = "leon-iphone";
						}
						{
							# Mobile: Leon's iPad
							hw-address = "88:66:5a:8b:32:15";
							ip-address = "192.168.1.101";
							hostname = "leon-ipad";
						}
						{
							# Mobile: Leon's Watch
							hw-address = "a0:d1:b3:f2:e9:e5";
							ip-address = "192.168.1.102";
							hostname = "leon-watch";
						}
						{
							# Device: Leon's Tesla Model 3
							hw-address = "c:29:8f:56:f4:2";
							ip-address = "192.168.1.103";
							hostname = "leon-tesla";
						}
						{
							# Mobile: Work iPhone
							hw-address = "d2:46:1a:f7:a9:eb";
							ip-address = "192.168.1.104";
							hostname = "work-iphone";
						}
						{
							# Mobile: Chanthaly's iPhone
							hw-address = "ca:be:fe:fd:4d:5a";
							ip-address = "192.168.1.105";
							hostname = "chanthaly-iphone";
						}
						{
							# Mobile: Chanthaly's Watch
							hw-address = "6e:17:aa:68:3a:16";
							ip-address = "192.168.1.106";
							hostname = "chanthaly-watch";
						}

						# OTHER DEVICES

						{
							# Device: Mitsubishi Wifi Control
							hw-address = "e8:e8:b7:ee:75:ee";
							ip-address = "192.168.1.140";
							hostname = "mitsubishi-wifi-control";
						}
						{
							# Device: Tesla Wall Connector
							hw-address = "98:ed:5c:f7:7a:8a";
							ip-address = "192.168.1.141";
							hostname = "tesla-wall-connector";
						}
						{
							# Device: Kitchen HomePod
							hw-address = "ac:bc:b5:d9:9b:a3";
							ip-address = "192.168.1.142";
							hostname = "kitchen-homepod";
						}
						{
							# Device: Lounge TV (Sony Bravia 65")
							hw-address = "ac:9b:a:2c:f0:55";
							ip-address = "192.168.1.143";
							hostname = "lounge-tv";
						}
						{
							# Device: Apple TV (Lounge)
							hw-address = "f0:b3:ec:1f:8c:4c";
							ip-address = "192.168.1.144";
							hostname = "lounge-apple-tv";
						}
						{
							# Device: Yoto Mini
							hw-address = "d4:8a:fc:ed:49:50";
							ip-address = "192.168.1.145";
							hostname = "yoto-mini";
						}
          ];
        }
      ];
    };
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
