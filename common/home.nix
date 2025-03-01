# Common Home Manager configuration
{ pkgs, config, secrets, ... }:

let
  isDevelopmentMachine = config.machine.kind == "development-machine";
  isUnifiController = config.machine.kind == "unifi-controller";
  useX11 = config.machine.gui.enabled;
in
{
  home = {
    stateVersion = "24.11";

    sessionVariables = {
      TERM = "xterm-256color";
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = "nvim";
      PAGER = "bat -p";
      MANPAGER = "bat -p";
      EXA_ICON_SPACING = "2";

      # Allow rust-analyzer to find the Rust source
      RUST_SRC_PATH = if isDevelopmentMachine then "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}" else "";

      # Use our current Java version always
      JAVA_HOME = if isDevelopmentMachine || isUnifiController then "${pkgs.jdk17}" else "";

      # use HiDPI for GDK/GTK apps
      GDK_SCALE = if useX11 then "2" else "";
    };
  };

  # Set up Home Manager programs (independent of nix programs!)
  programs = {
    # Shell
    fish = {
      enable = true;
      shellInit = ''
        fish_add_path -p /run/current-system/sw/bin
        fish_add_path -p /run/wrappers/bin
        if test -d $HOME/.cargo/bin
          fish_add_path $HOME/.cargo/bin
        end
        if test -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
          fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
        end
        if test -d "/Applications/Postgres.app/Contents/Versions/latest/bin"
          fish_add_path "/Applications/Postgres.app/Contents/Versions/latest/bin"
        end

        set -gx CDPATH . $HOME/${secrets.work-project-dir} $HOME/Source $HOME/source

        alias kc kubectl
        alias cat "bat -p"
        alias less "bat -p"
        alias ls "eza --icons"
        alias vi "nvim"
        alias vim "nvim"
        if test -x /run/wrappers/bin/sudo
          alias sudo "/run/wrappers/bin/sudo"
        end

        set -g fish_color_autosuggestion 6c6c6c
        '';
      plugins = [
        {
          name = "theme-bobthefish";
          src = pkgs.fetchFromGitHub {
            owner = "oh-my-fish";
            repo = "theme-bobthefish";
            rev = "faf92230221edcf6e62dd622cdff9ba947ca76c1";
            sha256 = "sha256-jBbm0wTNZ7jSoGFxRkTz96QHpc5ViAw9RGsRBkCQEIU=";
          };
        }
      ];
    };

    # Git
    git = {
      enable = true;
      lfs.enable = true;
      aliases = {
        co = "checkout";
        ca = "commit --all";
        fa = "fetch --all";
        fap = "!git fetch --all && git pull --autostash";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        st = "status";
        root = "rev-parse --show-toplevel";
      };
      includes = [
        {
          path = "~/.config/git/personal";
          condition = "gitdir:~/";
        }
        {
          path = "~/.config/git/personal";
          condition = "gitdir:/etc/nixos/";
        }
        {
          path = "~/.config/git/work";
          condition = "gitdir:~/${secrets.work-project-dir}/";
        }
        {
          path = "~/.config/git/work";
          condition = "gitdir:private/var/";
        }
      ];
      extraConfig = {
        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";
        delta.navigate = true;
        merge.conflictstyle = "zdiff3";
        branch.autosetuprebase = "always";
        color.ui = true;
        color.diff = "auto";
        color.status = "auto";
        color.interactive = "auto";
        color.pager = true;
        core.askPass = "";
        credential.helper = "store";
        credentialstore.locktimeoutms = 0;
        github.user = "leonbreedt";
        push.default = "tracking";
        pull.rebase = true;
        init.defaultBranch = "main";
      };
    };

    # NeoVIM
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      plugins = with pkgs; [
        # Theme/appearance
        vimPlugins.lightline-vim
        customVimPlugins.catppuccin-nvim
      ] ++ lib.optionals isDevelopmentMachine [
        # LSP
        vimPlugins.nvim-lspconfig

        # Language support
        vimPlugins.rust-vim
        vimPlugins.zig-vim
        vimPlugins.vim-nix
        vimPlugins.vim-fish

        # completion
        vimPlugins.cmp-nvim-lsp
        vimPlugins.cmp-buffer
        vimPlugins.cmp-path
        vimPlugins.cmp-cmdline
        vimPlugins.nvim-cmp
        vimPlugins.cmp-vsnip
        vimPlugins.vim-vsnip

        # popups
        vimPlugins.popfix
        customVimPlugins.popui-nvim

        # tree sitter
        (vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
          tree-sitter-c
          tree-sitter-cpp
          tree-sitter-go
          tree-sitter-nix
          tree-sitter-rust
        ]))
      ];

      extraConfig = builtins.readFile ./config/nvim;

      # Language servers
      extraPackages = with pkgs; lib.optionals isDevelopmentMachine [
        rust-analyzer
        gopls
      ];
    };

    # Utils
    gpg.enable = true;
    direnv.enable = true;

    # Terminal
    wezterm = {
      enable = useX11;
      extraConfig = builtins.readFile ./config/wezterm.lua;
    };
  };
}
