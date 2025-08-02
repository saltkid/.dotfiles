# dotfiles
@saltkid's dotfiles. Includes a build script for WSL Debian unstable and WSL 
archlinux to get GUI apps working. Has editable packages lists to add more 
packages, zsh plugins, and nerd fonts on build. 

# Table of Contents
- [Setup](#setup)
    - [Setup WSL from scratch](#setup-wsl-from-scratch)
    - [Setup Debain using build script](#setup-debian-using-build-script)
- [Build details](#build-details)
- [Post build details](#post-build-details)
- [Editable packages lists](#editable-packages-lists)

---

# Setup
If you just want the dotfiles, while in the dotfiles repo, do:
```bash
stow --adopt .
git restore . # to overwrite existing configs
```
This dotfiles include build scripts which duplicate my setup from a freshly
installed Debian/Arch on WSL
## Setup WSL from scratch
[reference](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux)
1. Activate needed features for WSL

    In an elevated powershell, do
    ```powershell
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestartwsl.exe --install
    ```
2. Install and update [WSL](https://github.com/microsoft/WSL)

    Restart PC to apply changes. In an elevated powershell, do
    ```powershell
    wsl.exe --update
    ```
## Setup Debian using build script
1. Install Debian

    In a non-elevated powershell, do
    ```powershell
    wsl.exe --set-default-version 2
    wsl.exe --install -d Debian
    ```
    This will launch Debian and prompt to create a user
2. Build my setup
    ```bash
    sudo apt-get install -y git
    git clone --recurse-submodules -j8 https://github.com/saltkid/dotfiles.git $HOME/dotfiles
    cd $HOME/dotfiles
    chmod +x ./scripts/wsl-debian-build.sh
    ./scripts/build.sh
    ```
    Then restart your shell. When the build fails, the script will try to undo
    the build process, where you can try executing `build.sh` again (after
    reading what went wrong of course).
3. Post build

    Restart WSL in powershell:
    ```powershell
    wsl.exe --shutdown; wsl
    ```
    Execute the post build script:
    ```bash
    cd $HOME/dotfiles
    chmod +x ./scripts/wsl-debian-post-build.sh
    ./scripts/post-build.sh
    ```
    Restart your shell again and the gui apps should work now. If you
    didn't edit `packages.txt`, [`wezterm`](https://github.com/wez/wezterm)
    will be installed so try that:
    ```bash
    wezterm
    ```
## Setup Arch using build script
1. Install Arch

    In a non-elevated powershell, do
    ```powershell
    wsl.exe --set-default-version 2
    wsl.exe --install -d archlinux
    ```
    This will launch Arch as root. Next steps will setup a small base and a
    default user
2. Install a small base, create the default user account, and make the user a
sudoer

    The script below cannot be in the repo since you'd need to do this before
    you can even clone my dotfiles. Be sure to read before copy pasting and
    executing :^)
    ```bash
    # Recommended to run `pacman -Syu` on first launch
    # The rest are what I consider an small base for all accounts
    pacman -Syu --noconfirm base-devel gnupg openssh man-db man-pages git vim sudo

    # Setting language
    cp /etc/environment /etc/environment.bak
    cp /etc/locale.gen /etc/locale.gen.bak
    echo "EDITOR=vim" >> /etc/environment
    echo "VISUAL=vim" >> /etc/environment
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "en_US ISO-8859-1" >> /etc/locale.gen
    locale-gen

    # Setting tty keyboard map
    cp /etc/locale.conf /etc/locale.conf.bak
    cp /etc/vconsole.conf /etc/vconsole.conf.bak
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo "KEYMAP=us" > /etc/vconsole.conf
    echo "FONT=ter-v28n" >> /etc/vconsole.conf

    # Add password for root account and add default user and password
    echo "Add password for root account"
    passwd
    read -p "Create user account. Enter username: " WSL_INSTALL_USERNAME
    useradd -mG wheel "$WSL_INSTALL_USERNAME"
    passwd "$WSL_INSTALL_USERNAME"
    cp /etc/wsl.conf /etc/wsl.conf.bak
    echo "
    [user]
    default=$WSL_INSTALL_USERNAME" >> /etc/wsl.conf

    # Allow the created user to use sudo by allowing all users under "wheel" group
    # to execute any action.
    # the regex is simply removing the `#` to uncomment wheel being able to
    # execute any action
    cp /etc/sudoers /etc/sudoers.bak
    sed -i '/^#\s%wheel ALL=(ALL:ALL) ALL$/s/^# //' /etc/sudoers && \
    # sanity check syntax errors
    visudo -c
    ```
3. Post build

    Restart WSL in powershell:
    ```powershell
    wsl.exe --terminate archlinux; wsl -d archlinux
    ```
    Clone the repo and execute the post build script:
    ```bash
    cd $HOME/dotfiles
    chmod +x ./scripts/wsl-arch-post-build.sh
    ./scripts/post-build.sh
    ```
    Restart your shell again and the gui apps should work now. Try out wezterm
    ```bash
    wezterm
    ```
--- 

# Build details
The build script will always install these packages, regardless of what is
specified in `packages.txt`
1. [`curl`](https://curl.se/docs/manpage.html) and [`gpg`](https://gnupg.org/)
for signing third party apt sources
2. [`mesa-utils`](https://wiki.debian.org/Mesa) for gui apps
2. [`stow`](https://wiki.debian.org/Mesa) for dotfile configs
3. [`uv`](https://github.com/astral-sh/uv) and
[`lazygit`](https://github.com/jesseduffield/lazygit) because both are not in
any apt sources
    - TODO: make these optional (as a part of `packages.txt`) when an apt
    source for these are found
4. [`neovim`](https://github.com/neovim/neovim) because it is outdated in the
official unstable debian source
    -  the executable is installed in `/opt/nvim/bin`
    - TODO: make this optional (as a part of `packages.txt`) when it gets
    updated
5. [`gt`](https://github.com/saltkid/gt) for finding git repos and cd'ing to
them. Might replace this with zoxide after trying it out but this is fine for
my simple workflows for now.

# Post Build details
The `post-build.sh` should fix wayland gui apps not working. See the comments
at the end of [this issue](https://github.com/microsoft/wslg/issues/1032). It
is marked as closed but is still relevant today since in my experience, after
restarting wsl with `wsl --shutdown; wsl`, wayland gui apps won't launch
anymore without this workaround.

# Editable packages lists
Packages must be separated by newline. The order does not matter EXCEPT for
`zsh-plugins.txt` which require syntax highlighting plugins to be last entry.
That's it.
1. `packages.txt`
    - packages installed by apt in the build script.
    - the build script requires `git`, `curl`, `gpg`, and `mesa-utils` so you
    don't need to include those since these will be installed anyway.
2. `nerd-fonts.txt`
    - from the [nerd fonts repo](https://github.com/ryanoasis/nerd-fonts).
    - To know which are the correct nerd font names,
    check the directory names
    [here](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts).
3. `zsh-plugins.txt`
    - only github plugins following the format: `owner/repo_name`.
    - must be plugins that need to be loaded, in which the init script is
    named like: `<plugin_name>.zsh`, `<plugin_name>.plugin.zsh`,
    `<plugin_name>.zsh-theme`, or `<plugin_name>.sh`.
        - this means no frameworks like Oh My Zsh.
