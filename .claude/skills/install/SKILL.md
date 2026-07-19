---
name: install
description: Install these dotfiles (tmux, vim config) onto the current machine — reads ONBOARDING.md, adapts the WSL-specific bits to whatever OS this actually is, and confirms with the user before any breaking change.
---

# Install dotfiles

Read `ONBOARDING.md` at this repo's root and carry out its steps on the
current machine, adapting as you go:

1. **Detect the environment first** — OS (Linux / macOS / WSL / native
   Windows), shell, and whether `tmux` / `vim` are already installed and at
   what version. Don't assume WSL just because `ONBOARDING.md` was written
   on WSL — check.
2. **Check prerequisites** per `ONBOARDING.md` step 1 (tmux >= 3.2, full vim
   not vim-tiny). Install whatever's missing for the detected OS.
3. **Before touching any target path** (`~/.tmux.conf`, `~/.vimrc`,
   `~/.tmux/cheatsheet.sh`), check what's already there. An existing file
   belongs to the user — never overwrite or move it silently.
4. **Ask before applying anything breaking.** This includes, at minimum:
   overwriting or moving an existing dotfile, replacing a symlink that
   points somewhere else, restarting or killing a running tmux server, and
   editing shell rc files (`.bashrc` / `.zshrc` / `.profile`, e.g. to add the
   tmux autostart block). State exactly what will change and why, then wait
   for explicit confirmation before doing it. This applies throughout every
   step below, not just the backup step.
5. **Adapt the WSL-only pieces** — the `default-command` PATH injection, the
   clip.exe/pbpaste/xclip clipboard branch, DECSCUSR passthrough — per the
   "Known gotchas" section of `ONBOARDING.md`. Add the correct clipboard tool
   (xclip/xsel for X11, wl-copy for Wayland) if on plain Linux; drop the
   Windows PATH injection if not on WSL.
6. **Symlink into place** per `ONBOARDING.md` step 3, only for the paths
   cleared in steps 3–4 above.
7. **Reload and verify** using the checklist in `ONBOARDING.md` step 4.

If this config is already symlinked in on this machine, treat a re-run as an
update/verify pass, not a fresh install.
