# Common packages. Some systems may not have all packages (e.g. routers/firewalls).

{ pkgs, config, ... }:

with pkgs; [
  bat
  btop
  eza
  fd
  fish
  fzf
  htop
  inetutils
  openssl
  pwgen
  ripgrep
  tree
  tmux
] ++ lib.optionals (config.machine.kind == "edge-router") [
  nmap
] ++ lib.optionals (config.machine.kind == "unifi-controller") [
] ++ lib.optionals (config.machine.kind == "development-machine") [
  awscli2
  bun
  cascadia-code
  coding-fonts
  curl
  delta
  deno
  difftastic
  du-dust
  fastfetch
  geist-mono
  gh
  graphviz
  git-lfs
  gnupg
  go
  gopls
  intel-one-mono
  jdk17
  jetbrains-mono
  jq
  kubectl
  kubelogin-oidc
  maven
  macchina
  neofetch
  nodePackages."@angular/cli"
  nodePackages."@tailwindcss/language-server"
  nodePackages.typescript-language-server
  pyright
  nodejs_20
  pkg-config
  python311Full
  sf-mono
  shellcheck
  sqlite
  terraform
  unrar
  unzip
  vault
  wrk
  xsv
  xh
  yq
  zip
] ++ lib.optionals (config.machine.kind == "development-machine" && config.machine.personal) [
  flyctl
  protobuf
  ruby_3_3
  rubyPackages_3_3.solargraph
  rustup
  rust-cbindgen
  step-cli
  typst
  zig
  zls
] ++ lib.optionals (config.machine.kind == "development-machine" && !config.machine.personal) [
  cloudfoundry-cli
  chromedriver
  vscode
]
