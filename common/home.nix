# Common Home Manager configuration
{ pkgs, ... }:

{
  home = {
    stateVersion = "23.05";

    sessionVariables = {
      TERM = "xterm-256color";
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = "nvim";
      PAGER = "bat -p";
      MANPAGER = "bat -p";
    };
  };

  # Set up Home Manager programs (independent of nix-darwin programs!)
  programs = {
    # Shell
    fish = {
      enable = true;
      shellInit = ''
        if test -d $HOME/.cargo/bin
          fish_add_path $HOME/.cargo/bin
        end
        if test -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
          fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
        end
        if test -d "/Applications/Postgres.app/Contents/Versions/latest/bin"
          fish_add_path "/Applications/Postgres.app/Contents/Versions/latest/bin"
        end

        set -gx CDPATH . $HOME/Source $HOME/source

        alias kc kubectl
        alias cat "bat -p"
        alias less "bat -p"
        alias ls "exa"
        '';
      plugins = [
        {
          name = "theme-bobthefish";
          src = pkgs.fetchFromGitHub {
            owner = "oh-my-fish";
            repo = "theme-bobthefish";
            rev = "2dcfcab653ae69ae95ab57217fe64c97ae05d8de";
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
      ];
      extraConfig = {
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

    # Utils
    gpg.enable = true;
    direnv.enable = true;
  };
}