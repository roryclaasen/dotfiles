# Git aliases

The aliases in [`.gitconfig`](../.gitconfig) provide shortcuts for common Git commands.
Run these commands from a Git repository.
Most aliases accept the same arguments as the commands they replace.
This document covers common workflows rather than every alias.

## Stage changes and inspect status

Staging selects file changes for your next commit.
Use `git s` to see the current branch and a short summary of file changes.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git a <path>` | `git add <path>` | Stage changes to a file or directory. |
| `git aa` | `git add --all` | Stage all additions, modifications, and deletions. |
| `git unstage <path>` | `git reset HEAD -- <path>` | Unstage changes without changing the file contents. |
| `git s` | `git status --short --branch` | Show the branch and file status. |

## List and manage branches

`git brl` lists local branches, and `git br` lists remote-tracking branches.
A remote-tracking branch is a local record of a remote branch.
Both listings show the author and relative author date of each branch's latest commit.
They sort by commit date, newest first.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git b` | `git branch` | List local branches. |
| `git b <branch>` | `git branch <branch>` | Create a branch without switching to it. |
| `git brl` | Formatted `git branch` | List local branches with dates and authors. |
| `git br` | Formatted `git for-each-ref` | List remote-tracking branches with dates and authors. |
| `git bd <branch>` or `git del <branch>` | `git branch -D <branch>` | Force-delete a local branch, even if it contains unmerged work. |

If you want to keep unmerged work, use `git branch -d <branch>` instead of `git bd` or `git del`.
For bulk cleanup, use [`git bprune`](#delete-unused-local-branches).

## Switch branches

`git co` and `git sw` both switch to an existing branch.
Use `git cob` to create a branch and switch to it in one command.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git co <branch>` | `git checkout <branch>` | Switch to an existing branch. |
| `git cob <branch>` | `git checkout -b <branch>` | Create and switch to a branch. |
| `git sw <branch>` | `git switch <branch>` | Switch to an existing branch. |

## Commit changes

Most commit aliases use the changes that you staged.
`git cma` also includes modified and deleted tracked files, but it does not include new files.
Signed commits require a configured signing key.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git c` | `git commit` | Open the editor to write a commit message. |
| `git cm "message"` | `git commit -m "message"` | Commit with a message from the command line. |
| `git cs` | `git commit -S` | Create a signed commit. |
| `git cma "message"` | `git commit -a -m "message"` | Commit changes to tracked files with a message. |
| `git camend` or `git c-` | `git commit --amend` | Replace the latest commit with an updated commit. |
| `git cempty -m "message"` | `git commit --allow-empty -m "message"` | Create a commit without file changes. |

Do not amend a commit that other people already use without coordinating with them.
Amending changes the commit ID.

## Fetch, update, and push

Fetching updates local records of remote branches without changing your checked-out files.
Rebasing reapplies local commits on top of another commit.
`git up` pulls with rebase, then initializes and updates submodules recursively.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git f` | `git fetch --prune --all --tags` | Fetch all remotes and tags, and remove stale remote-tracking references. |
| `git up` | `git pull --rebase --prune`, then `git submodule update --init --recursive` | Update the current branch and its submodules. |
| `git p` | `git push` | Push using Git's configured destination. |
| `git pa` | `git push --all` | Push all local branches. |
| `git pt` | `git push --tags` | Push all local tags. |
| `git done` | `git push origin HEAD` | Push the current branch to `origin`. |

`git f` does not delete local branches.
Despite its name, `git done` does not delete the branch or complete a pull request.

## View history and contributions

`git lg` shows the latest 30 commits with compact, colored output.
The contribution commands summarize authors rather than individual commits.
`git contribLoC` uses file blame data to count lines attributed to each author, so it can take longer on large repositories.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git lg` | Formatted `git log` | Show recent commits with IDs, dates, messages, authors, and branch labels. |
| `git last` | `git log -1 HEAD --stat` | Show the latest commit and a summary of its file changes. |
| `git lch` | `git log -n 1 --pretty=format:'%H'` | Print the full ID of the latest commit. |
| `git contrib` | `git shortlog -e --summary --numbered` | Show authors, email addresses, and commit counts, highest first. |
| `git contribLoC` | `git ls-files` and `git blame` pipeline | Show author line counts, highest first. |

## Compare changes with a diff tool

A diff tool displays file differences in an external application.
Both aliases below select a tool named `code`.
The configuration currently defines `vscode`, not `code`, so configure a tool named `code` before using these aliases.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git cdiff` | `git difftool --tool code` | Compare files with the external tool. |
| `git diffdir` | `git difftool --dir-diff --tool code` | Compare changed files as directories. |

## Manage worktrees

A worktree is another checkout that shares the same repository.
Worktrees let you work on different branches in separate directories.
Use `git wtl` to see which branches are checked out before you delete branches.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git wt <command>` | `git worktree <command>` | Run a worktree command. |
| `git wtl` | `git worktree list` | List worktrees and their checked-out branches. |
| `git wtadd <path> <branch>` | `git worktree add <path> <branch>` | Create a worktree for an existing branch. |
| `git wtdel <path>` | `git worktree remove <path>` | Remove a worktree, but keep its branch. |
| `git wtprune` | `git worktree prune` | Remove stale records for worktrees that no longer exist. |

`git wtdel` normally refuses to remove a worktree with uncommitted changes.
`git wtprune` does not delete branches or existing worktree directories.

## Delete unused local branches

`git bprune` deletes local branches that are not checked out in any worktree.
It always protects `main`, `master`, and the default branch on `origin`.
It uses the recorded default branch, or contacts `origin` if that record is missing.
It does not delete remote branches, remove worktrees, or filter branches by age.

Preview the branches before you delete them:

```sh
git bprune --dry-run
```

Use safe deletion to keep branches that Git considers unmerged:

```sh
git bprune
```

Safe deletion uses `git branch -d`.
An upstream branch is the branch that a local branch tracks.
Git requires each branch to be merged into its upstream branch, or into `HEAD` if no upstream exists.
The preview lists deletion attempts. Safe deletion can refuse branches in that list.

If you want to discard unmerged work, use `--force`.
This command can delete commits that exist only on those branches.
Preview forced deletion first:

```sh
git bprune --dry-run --force
git bprune --force
```

## Undo changes and remove files

Do not run cleanup or reset commands until you understand which changes they discard.
`git undo` keeps file changes, but `git res` discards changes to tracked files.
The clean aliases delete untracked files and directories, which Git cannot normally recover.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git undo` | `git reset HEAD~1 --mixed` | Remove the latest commit from the current branch and leave its changes unstaged. |
| `git res` | `git reset --hard` | Reset the index and tracked files to the current commit. |
| `git cl` | `git clean -df` | Delete untracked files and directories, but keep ignored files. |
| `git cl-all` | `git clean -xdf -e .vscode` | Delete untracked and ignored files and directories, except `.vscode`. |

`git res` can also remove untracked files that block Git from restoring tracked files.
If you only want to unstage changes, use `git unstage` instead.
Preview file cleanup before you delete anything:

```sh
git cl -n
git cl-all -n
```

## Inspect repository configuration

`git al` lists the full set of configured aliases.
Use it to find aliases that this document does not cover.
`git whoami` prints the configured commit author name and email address, not your authentication account.

| Command | Git command | Purpose |
| --- | --- | --- |
| `git root` | `git rev-parse --show-toplevel` | Print the root directory of the current checkout. |
| `git al` | `git config --get-regexp alias` | List configured aliases and their definitions. |
| `git whoami` | `git config user.name`, then `git config user.email` | Print the configured commit author identity. |
