# Nix configuration

Inspired by [Dustin Lyons'](https://github.com/dustinlyons/nixos-config) repo.

## Bootstrapping

### macOS

1. Install Nix using the [Determinate Systems](https://github.com/DeterminateSystems/nix-installer) Nix installer.

2. Add the nixpkgs channel.

   ```shell
   nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
   ```

3. Update the Nix channel.

   ```shell
   nix-channel --update
   ```

4. Install [home-manager](https://github.com/nix-community/home-manager). This is used to manage configuration files
   in $HOME.

   ```shell
   nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
   ```

5. Install [nix-darwin](https://github.com/LnL7/nix-darwin). This is used to manage macOS system configuration.

   ```shell
   nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
   ./result/bin/darwin-installer
   ```

   When asked, answer yes to managing Darwin with nix-channel.

6. Ensure that the current user is able to clone the private secrets repo before proceeding to the
   next step, e.g. set up the SSH keys. 
   
7. Install Homebrew (it's only used to install cask apps).

8. Run `env FLAKE=<NAME> ./rebuild`, where `<NAME>` is the name of your system in `flake.nix`, e.g.
   `athena` in my example. You can run this again after you make any changes to `.nix` files, to
   apply them to your system. If any files are reported as being in the way, move them out of the way
   and re-run.

### NixOS

1. Download the [latest NixOS stable distribution](https://nixos.org/manual/nixos/stable/index.html#sec-obtaining),
   these instructions were tested with 22.11. Download the minimal distribution, not graphical.
   
2. Create a [bootable USB](https://nixos.org/manual/nixos/stable/index.html#sec-booting-from-usb).

3. Boot from the USB device.

4. Create root and boot partitions and [format them with the file system of your choice](https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual), use the _nixos_ and _swap_ labels, as our configuration depends on these labels, and mount the file systems in `/mnt` and `/mnt/boot`, respectively.
   
5. Run `nixos-generate-config --root /mnt`

6. Clone this repository to `/mnt/etc/nixos/nixos-config`:

   ```shell
   nix-shell -p git
   echo https://<USER>:<GITHUB-TOKEN>@github.com > $HOME/.git-credentials
   git clone https://github.com/leonbreedt/nixos-config.git /mnt/etc/nixos/nixos-config
   ```

7. Ensure the `root` user has the SSH public key for cloning the secret repository 
   referenced by the `flake.nix`, it should be put in `/root/.ssh` with appropriate
   permissions. Run `ssh git@github.com` at least once, and save the GitHub SSH key
   (needed to avoid the `nixos-install` command hanging waiting for user input when
   cloning the secrets repo).

8. Run the installer, where `<SYSTEM>` is the name of the system in `flake.nix`:

   ```shell
   nixos-install --flake "/mnt/etc/nixos/nixos-config#<SYSTEM>" -v
   ```
   
   You will be prompted for a root password, which you can use after reboot to give
   the normal user a password to log in if you want to use X11. Only the normal user
   will be able to SSH in.
   
 9. Whenever you make changes to the configuration, you can 
    Run `env FLAKE=<SYSTEM> ./rebuild` in `/etc/nixos/nixos-config`, where 
    `<SYSTEM>` is the name of the system in `flake.nix`. This will run `nixos-rebuild`
    in flake mode, and switch to the built configuration afterwards.
   
### WSL

1. Build the latest `main` branch of [NixOS-WSL](https://github.com/nix-community/NixOS-WSL)
   on an existing NixOS system:

   ```shell
   nix build .#nixosConfigurations.mysystem.config.system.build.installer
   ```

3. This will produce a tarball in `./result/tarball/nixos-wsl-installer.tar.gz`,
   copy it somewhere (e.g USB).

4. Import the NixOS distribution tarball into the appropriate location (where you want
   `.\NixOS\` to be located, e.g. on a data drive:

   ```shell
   wsl --import NixOS .\NixOS\ nixos-wsl-installer.tar.gz --version 2
   ```

5. Launch the distribution:

   ```shell
   wsl -d NixOS
   ```

6. Clone this repository to `/etc/nixos/nixos-config`:

   ```shell
   nix-shell -p git
   git clone https://github.com/leonbreedt/nixos-config.git /etc/nixos/nixos-config
   ```

7. Ensure the `root` user has the SSH public key for cloning the secret repository 
   referenced by the `flake.nix`, it should be put in `/root/.ssh` with appropriate
   permissions. Run `ssh git@github.com` at least once, and save the GitHub SSH key
   (needed to avoid the `nixos-install` command hanging waiting for user input when
   cloning the secrets repo).

8. Change to `/etc/nixos/nixos-config` and run `env FLAKE=<WSL-FLAKE-NAME> ./rebuild`
   to do the initial build.   

## Using

Whenever you make changes to the configuration, just run `./rebuild` to apply it to your
system. Since the value of `FLAKE` defaults to the current hostname, you don't have to
pass a hostname for subsequent builds.

## Troubleshooting

There are still some rough edges with this configuration. Mainly around first-time
setup/retrieval of credentials from my private repo, you won't get access to it :)

If you remove the private repo input in `flake.nix` and the secrets references
you can likely get it going.
