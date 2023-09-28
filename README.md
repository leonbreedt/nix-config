# Nix configuration

Inspired by [Dustin Lyons'](https://github.com/dustinlyons/nixos-config) repo.

## Bootstrapping

### macOS

1. Install Nix using the [Determinate Systems](https://github.com/DeterminateSystems/nix-installer) Nix installer.

2. Install [Homebrew](https://brew.sh) (it's only used to install Casks and Mac App Store apps, its not in the `$PATH`).

3. Ensure that the current user is able to clone the private secrets repo before proceeding to the
   next step, by putting the SSH private key needed to clone the repo into `$HOME/.ssh/id_rsa`.

4. Run `env FLAKE=<NAME> ./bootstrap`. After a successful bootstrap, the hostname will be updated to match
   the flake.

5. Whenever you make configuration changes, run `./rebuild`. If any files are
   reported as being in the way, move them out of the way and re-run.

### NixOS

**TODO:** Below instructions are outdated and not adapted for complete flake rewrite.

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

**TODO:** Below instructions are outdated and not adapted for complete flake rewrite.

1. Clone this repository on an existing NixOS system, and ensure
   `nativeSystemd` is set to `false` in `wsl/default.nix`.

3. Build the latest `main` branch on an existing NixOS system:

   ```shell
   nix build .#nixosConfigurations.<WSL-CONFIG-NAME>.config.system.build.installer
   ```

4. This will produce a tarball in `./result/tarball/nixos-wsl-installer.tar.gz`,
   copy it somewhere (e.g USB).

5. Import the NixOS distribution tarball into the appropriate location (where you want
   `.\NixOS\` to be located, e.g. on a data drive:

   ```shell
   wsl --import NixOS .\NixOS\ nixos-wsl-installer.tar.gz --version 2
   ```

6. Launch the distribution, after it is finished it should launch the shell
   for the user in your configuration:

   ```shell
   wsl -d NixOS
   ```

7. Clone this repository to `/etc/nixos/nixos-config`:

   ```shell
   sudo mkdir /etc/nixos
   sudo git clone https://github.com/leonbreedt/nixos-config.git /etc/nixos/nixos-config
   ```

8. Change to `/etc/nixos/nixos-config` and run `./rebuild` to do the initial build.

## Using

Whenever you make changes to the configuration, just run `./rebuild` in the cloned
flake  directory to apply it to your system. Since the value of `FLAKE` defaults
to the current hostname, you don't have to pass a hostname for subsequent builds,
once it has been built once.

## Troubleshooting

There are still some rough edges with this configuration. Mainly around first-time
setup/retrieval of credentials from my private repo, you won't get access to it :)

If you remove the private repo input in `flake.nix` and the secrets references
you can likely get it going.

### Missing commands do not print derivations that resolve it

If you run a command that is not installed, and you get an error like this:

```shell
DBI connect('dbname=/nix/var/nix/profiles/per-user/root/channels/nixos/programs.sqlite','',...) failed:
unable to open database file at /run/current-system/sw/bin/command-not-found line 13.
```

Then you can likely resolve it by updating your Nix channels for the root user.

```shell
sudo nix-channel --update
```

### Rust completion doesn't work in VIM

Since are using `rustup` instead of global native Nix Rust packages, make
sure `rust-analyzer` is installed:

```shell
rustup component add rust-analyzer
```
