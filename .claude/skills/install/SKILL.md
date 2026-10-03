---
name: install
description: Install these dotfiles (tmux, vim, Claude Code statusline) onto the current machine — reads ONBOARDING.md, handles the per-OS bits (clipboard tool, macOS Option key) for whatever OS this actually is, and confirms with the user before any breaking change.
---

# Install dotfiles

Read `ONBOARDING.md` at this repo's root and carry out its steps on the
current machine, adapting as you go:

1. **Detect the environment first** — OS (Linux / macOS / WSL / native
   Windows), shell, and whether `tmux` / `vim` are already installed and at
   what version. Don't assume WSL just because `ONBOARDING.md` was written
   on WSL — check.
2. **Check prerequisites** per `ONBOARDING.md` step 1 (tmux >= 3.2, full vim
   not vim-tiny, python3 for the statusline). Install whatever's missing for
   the detected OS.
3. **Before touching any target path** (`~/.tmux.conf`, `~/.vimrc`,
   `~/.tmux/cheatsheet.sh`, `~/.tmux/clip.sh`, `~/.claude/statusline.py`),
   check what's already there. An existing file belongs to the user — never
   overwrite or move it silently.
4. **Ask before applying anything breaking.** This includes, at minimum:
   overwriting or moving an existing dotfile, replacing a symlink that
   points somewhere else, restarting or killing a running tmux server, and
   editing shell rc files (`.bashrc` / `.zshrc` / `.profile`, e.g. to add the
   tmux autostart block). State exactly what will change and why, then wait
   for explicit confirmation before doing it. This applies throughout every
   step below, not just the backup step.
5. **Handle the per-platform pieces** per the "Known gotchas" section of
   `ONBOARDING.md`. The config itself needs no edits per OS — clipboard
   tooling is picked at runtime by `.tmux/clip.sh`. On plain Linux, install a
   clipboard tool it can use (wl-clipboard for Wayland, xclip/xsel for X11).
   On macOS, check the terminal sends Option as Meta (tell the user how to
   turn it on; don't edit terminal prefs yourself). If a pre-existing
   `~/.tmux.conf` has settings the user wants to keep, offer to move them
   into `~/.tmux.local.conf` instead of editing the shared `.tmux.conf`.
6. **Symlink into place** per `ONBOARDING.md` step 3, only for the paths
   cleared in steps 3–4 above.
7. **Merge the `statusLine` key into `~/.claude/settings.json`** per
   `ONBOARDING.md` step 4 — merge, never overwrite: that file holds the user's
   own model, theme, and plugin settings. An existing `statusLine` pointing
   elsewhere is a breaking change under step 4's rule; ask first.
8. **Reload and verify** using the checklist in `ONBOARDING.md` step 5.

If this config is already symlinked in on this machine, treat a re-run as an
update/verify pass, not a fresh install.
