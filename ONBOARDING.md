# Dotfiles onboarding — tmux + vim + Claude Code statusline

This repo holds `.tmux.conf`, `.vimrc`, `.tmux/cheatsheet.sh`, and
`.claude/statusline.py`. Files are laid out exactly as they sit under `$HOME`, so
installing is a 1:1 symlink per file — no renaming, no templating.

The one exception is `~/.claude/settings.json` (step 4): it holds the rest of
your Claude Code config, so the statusline entry gets merged into it rather than
symlinked over it.

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
python3 -V  # any 3.x; statusline.py is stdlib-only
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

`python3` is only needed for the Claude Code statusline. If it's missing and you
don't want it, skip steps 4 and the statusline parts of 2–3 — nothing else in
this repo depends on it.

## 2. Back up existing dotfiles

Don't overwrite anything blindly — check first:

```bash
for f in .tmux.conf .vimrc .tmux/cheatsheet.sh .claude/statusline.py; do
  [ -e "$HOME/$f" ] && echo "EXISTS: $HOME/$f"
done
```

For anything that exists and isn't already a symlink to this repo, move it aside:

```bash
mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"      # only if it exists
mv "$HOME/.vimrc" "$HOME/.vimrc.bak"               # only if it exists
mv "$HOME/.tmux/cheatsheet.sh" "$HOME/.tmux/cheatsheet.sh.bak"  # only if it exists
mv "$HOME/.claude/statusline.py" "$HOME/.claude/statusline.py.bak"  # only if it exists
```

## 3. Symlink into place

Run from wherever you cloned this repo (`$REPO` below):

```bash
REPO="$(pwd)"
mkdir -p "$HOME/.tmux" "$HOME/.claude"
ln -sf "$REPO/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$REPO/.vimrc" "$HOME/.vimrc"
ln -sf "$REPO/.tmux/cheatsheet.sh" "$HOME/.tmux/cheatsheet.sh"
ln -sf "$REPO/.claude/statusline.py" "$HOME/.claude/statusline.py"
```

## 4. Point Claude Code at the statusline

`~/.claude/settings.json` is user-owned and holds unrelated keys (model, theme,
plugins), so this is a merge, not a symlink — add the `statusLine` key and leave
everything else alone:

```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/statusline.py"
  }
}
```

If the file doesn't exist yet, create it with just that object. If it does, add
the key without disturbing the rest — and if a `statusLine` key is already there
pointing somewhere else, that's the user's existing statusline: ask before
replacing it.

Claude Code re-reads settings on the next render; no restart needed.

## 5. Reload and verify

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
- [ ] Claude Code shows two status lines: model + rate limits on top, context
      gauge + path + branch below. Test it standalone without launching Claude:
      ```bash
      echo '{"model":{"display_name":"Opus 5 (1M context)"},"workspace":{"current_dir":"'"$PWD"'"},"context_window":{"used_percentage":31,"total_input_tokens":62000,"context_window_size":200000}}' | python3 ~/.claude/statusline.py
      ```
      Should print the gauge, the path, and the current git branch.

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
3. **`statusline.py`'s path shortening** rewrites `/mnt/<drive>/Users/<you>` to
   `C:~` — a WSL-ism, and deliberately only when the Windows username matches
   yours. On native Linux/macOS that branch never fires and paths render
   normally, so it's safe to leave in place.
4. **Cursor-shape passthrough** (`Ss`/`Se` in `.tmux.conf`'s `terminal-overrides`,
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
