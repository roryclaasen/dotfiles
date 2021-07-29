# Rory Claasen's Dotfiles

## Instalation

### Using Git and the setup script

You can clone the repository wherever you want (well on same drive as `$home`). (I like to keep it in `$home\dotfiles`.) The setup script will setup symlinks to the cloned repository.

From PowerShell:

```posh
git clone https://github.com/roryclaasen/dotfiles.git; cd dotfiles; . .\setup.ps1
```

To update your settings, cd into your local dotfiles-windows repository within PowerShell and then:

```posh
. .\setup.ps1
```

Note: You must have your execution policy set to unrestricted (or at least in bypass) for this to work: `Set-ExecutionPolicy Unrestricted`.

### Install dependencies and packages

When setting up a new Windows box, you may want to install some common packages, utilities, and dependencies.
I've added options in the setup menu to install or update various programs that I use frequentaly either for work or personal use.

Installation is handled by [winget (Windows Package Manager)](https://github.com/microsoft/winget-cli), you will need to make sure that this is installed on your system prior to running the setup.

> The winget tool requires Windows 10 1809 (build 17763) or later at this time.
