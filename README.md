# Rory Claasen's Dotfiles

Config files and PowerShell scripts I use for my Windows machine(s).

## Instalation

You can clone the repository wherever you want (well on same drive as `$home`). (I like to keep it in `~\dotfiles`.) The setup script will setup symlinks to the cloned repository.

From PowerShell:

```sh
git clone https://github.com/roryclaasen/dotfiles.git; cd dotfiles; .\install
```

To update your settings, cd into your local dotfiles repository within PowerShell and then run:

```sh
.\install
```

Note: You must have your execution policy set to unrestricted (or at least in bypass) for this to work: `Set-ExecutionPolicy Unrestricted`.
