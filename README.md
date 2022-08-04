# Rory Claasen's Dotfiles

## Instalation

You can clone the repository wherever you want (well on same drive as `$home`). (I like to keep it in `~\dotfiles`.) The setup script will setup symlinks to the cloned repository.

From PowerShell:

```sh
git clone https://github.com/roryclaasen/dotfiles.git; cd dotfiles; .\setup.ps1
```

To update your settings, cd into your local dotfiles repository within PowerShell and then:

```sh
.\setup.ps1
```

Note: You must have your execution policy set to unrestricted (or at least in bypass) for this to work: `Set-ExecutionPolicy Unrestricted`.
