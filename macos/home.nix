# macOS-specific Home Manager configuration
{ pkgs, user, configdir, ... }:

{
  home-manager.users.${user}.home.activation = {
    setRootCaCertificates = ''
      sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ${configdir}/ssl/certs/sector42-ca.pem
    '';
  };
}
