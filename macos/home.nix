# macOS-specific Home Manager configuration
{ pkgs, configdir, ... }:

{
  home.activation = {
    setRootCaCertificates = ''
      security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ${configdir}/ssl/certs/sector42-ca.pem
    '';
  };
}
