{ lib, stdenvNoCC, fetchurl, unzip, p7zip }:

stdenvNoCC.mkDerivation rec {
  pname = "sf-pro";
  version = "1";

  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    sha256 = "sha256-B8xljBAqOoRFXvSOkOKDDWeYUebtMmQLJ8lF05iFnXk=";
  };

  nativeBuildInputs = [ p7zip ];
  sourceRoot = ".";
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    7z x ${src}
    cd SFProFonts
    7z x 'SF Pro Fonts.pkg'
    7z x 'Payload~'

    install -m444 -Dt $out/share/fonts/opentype Library/Fonts/*.otf

    runHook postInstall
  '';

  meta = {
    description = "Apple San Francisco, New York fonts";
    homepage = "https://developer.apple.com/fonts/";
    license = lib.licenses.unfree;
  };
}
