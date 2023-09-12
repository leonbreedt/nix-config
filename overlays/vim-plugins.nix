self: super: {
  customVimPlugins = with self; {
    catppuccin-nvim = vimUtils.buildVimPlugin {
      name = "catppuccin-nvim";
      src = fetchFromGitHub {
        owner = "catppuccin";
        repo = "nvim";
        rev = "cd676faa020b34e6617398835b5fa3d1c2e8895c";
        sha256 = "00lww24cdnayclxx4kkv19vjysdw1qvngrf23w53v6x4f08s24my";
      };
    };

    popui-nvim = vimUtils.buildVimPlugin {
      name = "popui-nvim";
      src = fetchFromGitHub {
        owner = "hood";
        repo = "popui.nvim";
        rev = "5836baf9514f1a463e6617b5ea72669b597f8259";
        sha256 = "1ga4n5b7p4v96nnfjbmy0b6zzacwnp2axyqmckgd52wn3lg407q9";
      };
    };
  };
}
