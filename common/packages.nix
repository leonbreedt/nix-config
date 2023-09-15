# Common packages installed on all systems

{ pkgs }:

with pkgs; [
  awscli2
  bat
  bun
  cascadia-code
  cloudfoundry-cli
  curl
  deno
  difftastic
  du-dust
  eza
  fd
  fish
  flyctl
  fzf
  gh
  git-lfs
  gnupg
  go
  gopls
  htop
  inetutils
  jdk17
  jetbrains-mono
  jq
  kubectl
  kubelogin-oidc
  maven
  neofetch
  nmap
  nodePackages."@tailwindcss/language-server"
  nodePackages.typescript-language-server
  nodejs-18_x
  openssl
  pinentry
  pkg-config
  pwgen
  ripgrep
  rustup
  sf-mono
  step-cli
  sqlite
  terraform
  tree
  tmux
  unrar
  unzip
  vault
  wrk
  xsv
  zig
  zls
  zip
]
