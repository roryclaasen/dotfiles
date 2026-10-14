# Git aliases

The aliases in `.gitconfig` provide shortcuts for common Git commands.

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
Git requires each branch to be merged into its upstream branch, or into `HEAD` if no upstream exists.
The preview lists deletion attempts. Safe deletion can refuse branches in that list.

If you want to discard unmerged work, use `--force`.
This command can delete commits that exist only on those branches.
Preview forced deletion first:

```sh
git bprune --dry-run --force
git bprune --force
```
