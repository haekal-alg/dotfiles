# Dotfiles onboarding — tmux + vim

This repo holds `.tmux.conf`, `.vimrc`, and `.tmux/cheatsheet.sh`. Files are laid
out exactly as they sit under `$HOME`, so installing is a 1:1 symlink per file —
no renaming, no templating.

Read this whole file before running anything — the "Known gotchas" section at
the bottom explains why two of these steps aren't just `apt install && symlink`.

**Ask before applying anything breaking.** Overwriting or moving an existing
dotfile, replacing a symlink that points somewhere else, restarting/killing a
running tmux server, and editing shell rc files (`.bashrc`/`.zshrc`/`.profile`)
all count as breaking changes. State exactly what will change and why, then
wait for explicit confirmation before doing it — this applies to every step
below, not just the backup step.

## 1. Check prerequisites

```bash
tmux -V     # need >= 3.2 (uses display-popup, pane-border-lines, pane-border-format)
vim --version | head -1   # need the FULL vim package, not vim-tiny
```

If `tmux -V` is missing or reports < 3.2:
- Debian/Ubuntu: `sudo apt update && sudo apt install tmux` — check the version
  again after; some stable repos (e.g. Debian bullseye) ship tmux 3.1c, which is
  too old for this config. If so, pull a newer build from backports or a static
  binary release instead of stable.
- macOS: `brew install tmux`

If vim reports "tiny" anywhere in `vim --version`, replace it — the tiny build
lacks `+eval`/`+autocmd`, which the yank-to-tmux-buffer bridge in `.vimrc` needs:
- Debian/Ubuntu: `sudo apt install vim` (pulls the full package, resolves
  `vim-tiny` alternatives automatically)
- macOS: vim ships full-featured by default, no action needed

## 2. Back up existing dotfiles

Don't overwrite anything blindly — check first:

```bash
for f in .tmux.conf .vimrc .tmux/cheatsheet.sh; do
  [ -e "$HOME/$f" ] && echo "EXISTS: $HOME/$f"
done
```

For anything that exists and isn't already a symlink to this repo, move it aside:

```bash
mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"      # only if it exists
mv "$HOME/.vimrc" "$HOME/.vimrc.bak"               # only if it exists
mv "$HOME/.tmux/cheatsheet.sh" "$HOME/.tmux/cheatsheet.sh.bak"  # only if it exists
```

## 3. Symlink into place

Run from wherever you cloned this repo (`$REPO` below):

```bash
REPO="$(pwd)"
mkdir -p "$HOME/.tmux"
ln -sf "$REPO/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$REPO/.vimrc" "$HOME/.vimrc"
ln -sf "$REPO/.tmux/cheatsheet.sh" "$HOME/.tmux/cheatsheet.sh"
```

## 4. Reload and verify

```bash
tmux source-file ~/.tmux.conf     # if already inside a tmux session
```

Checklist:
- [ ] `prefix` is `Alt+q` (not the default `Ctrl+b`)
- [ ] `prefix` + `?` opens the shortcuts popup (proves `cheatsheet.sh` resolved)
- [ ] `prefix` + `|` / `-` splits panes in the current path
- [ ] Open vim, enter insert mode — cursor should switch from block to a thin bar
      (only visible if your terminal + tmux both support DECSCUSR passthrough,
      see gotchas below)
- [ ] Yank a line in vim (`yy`) inside tmux, then `prefix` + `p` in another pane
      — should paste the yanked text

## Known gotchas — this config assumes WSL2

These dotfiles were written on WSL2 with the default `C:` drive mount. Check
which of these applies before assuming a clean install:

1. **`default-command` in `.tmux.conf`** hardcodes
   `PATH="$PATH:/mnt/c/Windows/System32:/mnt/c/Windows"`. Only meaningful under
   WSL with the default mount — harmless dead PATH entries on native Linux/macOS,
   but pointless there. Remove the line if not on WSL.
2. **Copy-mode `y` binding** branches on `uname -r | grep -qi microsoft`:
   WSL → pipes to `clip.exe` (needs WSL interop enabled, on by default),
   anything else → `pbcopy` (macOS only). **On plain Linux (X11/Wayland) neither
   branch applies and system-clipboard copy silently no-ops.** If the target
   machine is plain Linux, add a third branch using `xclip`/`xsel` (X11) or
   `wl-copy` (Wayland) — install whichever matches the display server first.
3. **Cursor-shape passthrough** (`Ss`/`Se` in `.tmux.conf`'s `terminal-overrides`,
   `t_SI`/`t_SR`/`t_EI` in `.vimrc`) needs the *outer* terminal to support
   DECSCUSR escapes. Windows Terminal and iTerm2 do; some minimal/embedded
   terminals don't — if the cursor doesn't change shape in insert mode, this is
   why, and it's cosmetic only (safe to ignore).

## What's deliberately NOT in this repo

No `install.sh` — this file is the install script, meant to be handed to
Claude Code (or read by a human) so each step gets checked before it runs
rather than executed blind. No tmux plugin manager (TPM) or vim plugin manager
either — `.tmux.conf` and `.vimrc` are both self-contained, nothing to bootstrap
beyond tmux/vim themselves.
