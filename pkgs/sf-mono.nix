{ lib, stdenvNoCC, fetchurl, unzip, p7zip }:

stdenvNoCC.mkDerivation rec {
  pname = "sf-mono";
  version = "1";

  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
    sha256 = "sha256-pqkYgJZttKKHqTYobBUjud0fW79dS5tdzYJ23we9TW4=";
  };

  nativeBuildInputs = [ p7zip ];
  sourceRoot = ".";
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    7z x ${src}
    cd SFMonoFonts
    7z x 'SF Mono Fonts.pkg'
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
