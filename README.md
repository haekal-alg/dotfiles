# dotfiles

## What this is

My tmux, vim, Claude Code, GlazeWM, Zebar and tacky-borders config, the stuff I actually use day to day. Used on WSL2 and macOS from the same files: the OS-specific clipboard handling lives in one helper script (`.tmux/clip.sh`) that picks the right tool at runtime, and per-machine tweaks go in an untracked `~/.tmux.local.conf`. Plain Linux should work once a clipboard tool (wl-clipboard, xclip or xsel) is installed, but isn't tested. Still not plug-and-drop: read `ONBOARDING.md`'s gotchas, or hand the install to an AI agent (see below).

## Install (AI-assisted)

Clone the repo, `cd` into it, then run:

```bash
claude
```

and inside the session, run:

```
/install
```

This triggers the `.claude/skills/install` skill, which reads `ONBOARDING.md`, handles the per-OS bits for your platform, links the Claude Code skills in this repo, and asks for confirmation before any breaking change (overwriting an existing dotfile, restarting a running tmux server, editing shell rc files, etc).

`ONBOARDING.md` is written as a step-by-step script meant to be read and run by an agent (or a careful human), not executed blind. It covers prerequisites, backing up existing dotfiles, symlinking, and the per-platform gotchas.

## Tools I use

The day-to-day setup this config sits in:

- **[Alacritty](https://github.com/alacritty/alacritty)** — GPU-accelerated, cross-platform terminal emulator. No built-in multiplexer, which is exactly what the tmux config here is for.
- **[tmux](https://github.com/tmux/tmux)** — terminal multiplexer. `.tmux.conf` here is written against **3.7b**; a few options it uses don't exist in the 3.2a that Ubuntu's apt still ships.
- **[Neovim](https://github.com/neovim/neovim)** — editor. It reads the `.vimrc` in this repo via a one-line `~/.config/nvim/init.lua` shim (`vim.cmd.source(vim.fn.expand("~/.vimrc"))`). That shim isn't tracked here, so create it yourself if you want the vim config to apply under Neovim.
- **[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)** — zsh framework. The login shell is zsh, so the shell-side pieces referenced below (PATH ordering, the tmux autostart, the Windows PATH injection) live in `~/.zshrc` rather than `~/.bashrc`.
- **[GlazeWM](https://github.com/glzr-io/glazewm)** — i3-inspired tiling window manager for Windows. I run my own fork, [haekal-alg/glazewm](https://github.com/haekal-alg/glazewm) (`animations` branch), which adds macOS-style workspace-switch slide animations on top of the unmerged upstream PR #1392.
- **[Zebar](https://github.com/glzr-io/zebar)** — customizable, cross-platform status bar/widget tool, from the same team as GlazeWM.
- **[tacky-borders](https://github.com/lukeyou05/tacky-borders)** — customizable window border accents (color, gradient, radius) for Windows 10/11.
- **[agent-yes](https://github.com/snomiao/agent-yes)** — runs AI coding agents (Claude, Codex, Gemini, ...) unattended: auto-answers prompts and auto-retries on rate limits.

tmux, vim, GlazeWM, Zebar and tacky-borders are configured here. Nothing else on that list has its config tracked in this repo.

The Windows-side configs are **copies**, not symlinks: a symlink into `%USERPROFILE%` would store the Windows account name as its target in git (same reason `alacritty.toml` is ignored). They mirror their home-relative location, so restoring means copying them back by hand:

- `.glzr/glazewm/config.pr1392.yaml` → `%USERPROFILE%\.glzr\glazewm\`. Uses the fork's `animations` block, which stock GlazeWM doesn't know; start the fork with `glazewm start --config <that path>`. Paths in it use `%USERPROFILE%`, which `shell-exec` expands.
- `.config/tacky-borders/config.yaml` → `%USERPROFILE%\.config\tacky-borders\`.
- `.glzr/zebar/` → `%USERPROFILE%\.glzr\zebar\`: `settings.json` starts the `vitrine` widget pack (`vitrine/`), and `debug/zebar_logged.vbs` is the launcher GlazeWM's startup command runs. It starts Zebar hidden with its log written to a timestamped file in `debug/`; those logs aren't tracked and can grow large. The launcher points at Zebar's default install path, `C:\Program Files\glzr.io\Zebar\zebar.exe`.

Edit the live files and copy them back here; nothing keeps the two in sync.

## What this config can do

**tmux (`.tmux.conf`)**
- Prefix remapped to `Alt+q`
- Pane splits and new windows that keep the current pane's working directory
- `Alt+h/j/k/l` pane navigation without the prefix
- Mouse mode, 10k-line scrollback, vi-style copy mode
- Pane labeling (`prefix T`) for telling parallel terminal sessions apart at a glance
- Built-in shortcuts popup (`prefix ?`)
- Machine clipboard bridge: `prefix p` and `prefix ]` pull from the OS clipboard (win32yank on WSL, pbpaste on macOS, wl-paste/xclip/xsel on Linux, all via `.tmux/clip.sh`) before pasting; copy-mode `y` pushes a selection back out to the OS clipboard
- Cursor-shape (DECSCUSR) passthrough so vim's insert-mode cursor renders correctly through tmux
- Sessions survive reboots: tmux-resurrect + tmux-continuum (via TPM, self-bootstrapping) auto-save every 5 min and auto-restore on the next tmux start. `prefix C-s` / `prefix C-r` save / restore by hand

**vim (`.vimrc`)**
- 4-space indentation, no backup/swap files, autoread
- Yank bridges: yanking in vim pushes to both tmux's paste buffer and the OS clipboard
- Paste bridge: `p`/`P` pull from the OS clipboard first, so paste always has the latest system-clipboard content
- Cursor shape changes between normal and insert mode

**Claude Code statusline (`.claude/statusline.py`)**
- Two lines: model + effort + 5h/7d rate-limit usage with reset countdowns on top; context-window gauge, working directory, and git branch below
- Context gauge and rate-limit percentages are color-coded green/yellow/red, so "how close am I to a compact" is readable without parsing numbers
- Branch is read straight out of `.git/HEAD` rather than by shelling out to git — the statusline redraws constantly, and on WSL's `/mnt/c` a `git` subprocess costs ~60ms against ~7ms for the file read
- Path is middle-elided to fit, and shrinks to make room for whatever the gauge and branch need
- Stdlib-only Python 3, no dependencies

**Claude Code skills (`.claude/skills/`)**
- `generate-prd`: turns specs, a codebase, or a feature idea into a PRD published as an Artifact page
- `generate-specs`: interviews you into a requirements package (`specs/`) grounded in the codebase
- `generate-user-stories`: groups git history into user stories with commit proof, for time tracking
- `talk-to-me-im-human`: rewrites a technical answer for a PM; loads the [humanizer](https://github.com/blader/humanizer) skill, which `/install` clones at a pinned tag
- `install`: the installer itself, only useful inside this repo
- All of them load when Claude Code runs inside this repo. `/install` links every one except `install` itself into `~/.claude/skills/`, so they work everywhere

**GlazeWM (`.glzr/glazewm/config.pr1392.yaml`)**
- Horizontal workspace-switch slide, 400 ms, `cubic_bezier(0.2, 0.9, 0.3, 1.0)` (full speed from the first frame, long settle, no bounce)
- Moving a window (`Alt+Shift+arrow`) slides it, and the neighbours that resize to fill the gap slide with it: 150 ms ease-in-out
- New tiled windows slide in from the right (150 ms); `Alt+Shift+Q` fades the window out. Windows closed any other way (their own X, Ctrl+W) just vanish, since they're gone before GlazeWM hears about it
- Starts Zebar on launch; `Alt+,` renames the focused workspace through Zebar's inline input

**Zebar (`.glzr/zebar/vitrine/`)**
- Translucent top bar: workspace buttons on the left, date in the middle, status on the right
- The focus highlight slides between workspace buttons on the same 400 ms curve as GlazeWM's workspace slide (jumps instead with Windows' reduce-motion setting on)
- Inline workspace rename: double-click a button, or `Alt+,` in GlazeWM; Enter saves, Esc cancels
- Right side: GlazeWM pause and binding-mode buttons, tiling-direction toggle, Bluetooth device with battery level (click to cycle devices), Wi-Fi network, volume with mute, battery with charging glyph
- Bluetooth has no Zebar provider, so `vitrine/bluetooth.ps1` is polled through PowerShell; the script path is built from `%USERPROFILE%` at run time

**tacky-borders (`.config/tacky-borders/config.yaml`)**
- 3 px square blue focus border; unfocused windows get GlazeWM's own gray border instead
- 200 ms fade when focus moves between windows
- Forced on for Alacritty, which has no native frame with `decorations = "None"`

**Other**
- `.gitattributes` forces LF line endings, since the repo moves between Windows and Linux
