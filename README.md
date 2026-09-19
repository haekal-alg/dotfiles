# dotfiles

## What this is

My tmux and vim config, the stuff I actually use day to day. Written and tested on WSL2 only, so a few pieces assume that environment specifically: the Windows-clipboard bridge (win32yank/clip.exe), the injected `/mnt/c/Windows` PATH, the DECSCUSR cursor passthrough. Not a plug-and-drop config. Read through the files and reconfigure the WSL-specific bits for your platform, or hand that pass to an AI agent instead of doing it by hand (see below).

## Install (AI-assisted)

Clone the repo, `cd` into it, then run:

```bash
claude
```

and inside the session, run:

```
/install
```

This triggers the `.claude/skills/install` skill, which reads `ONBOARDING.md`, adapts anything WSL-specific if you're not on WSL, and asks for confirmation before any breaking change (overwriting an existing dotfile, restarting a running tmux server, editing shell rc files, etc).

`ONBOARDING.md` is written as a step-by-step script meant to be read and run by an agent (or a careful human), not executed blind. It covers prerequisites, backing up existing dotfiles, symlinking, and the WSL-specific gotchas that won't apply everywhere.

## Tools I use

The day-to-day setup this config sits in:

- **[Alacritty](https://github.com/alacritty/alacritty)** — GPU-accelerated, cross-platform terminal emulator. No built-in multiplexer, which is exactly what the tmux config here is for.
- **[tmux](https://github.com/tmux/tmux)** — terminal multiplexer. `.tmux.conf` here is written against **3.7b**; a few options it uses don't exist in the 3.2a that Ubuntu's apt still ships.
- **[Neovim](https://github.com/neovim/neovim)** — editor. It reads the `.vimrc` in this repo via a one-line `~/.config/nvim/init.lua` shim (`vim.cmd.source(vim.fn.expand("~/.vimrc"))`). That shim isn't tracked here, so create it yourself if you want the vim config to apply under Neovim.
- **[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)** — zsh framework. The login shell is zsh, so the shell-side pieces referenced below (PATH ordering, the tmux autostart, the Windows PATH injection) live in `~/.zshrc` rather than `~/.bashrc`.
- **[GlazeWM](https://github.com/glzr-io/glazewm)** — i3-inspired tiling window manager for Windows.
- **[agent-yes](https://github.com/snomiao/agent-yes)** — runs AI coding agents (Claude, Codex, Gemini, ...) unattended: auto-answers prompts and auto-retries on rate limits.

Only tmux and vim are configured here. Nothing else on that list has its config tracked in this repo.

## What this config can do

**tmux (`.tmux.conf`)**
- Prefix remapped to `Alt+q`
- Pane splits and new windows that keep the current pane's working directory
- `Alt+h/j/k/l` pane navigation without the prefix
- Mouse mode, 10k-line scrollback, vi-style copy mode
- Pane labeling (`prefix T`) for telling parallel terminal sessions apart at a glance
- Built-in shortcuts popup (`prefix ?`)
- Machine clipboard bridge: `prefix p` and `prefix ]` pull from the OS clipboard (win32yank on WSL, pbpaste on macOS) before pasting; copy-mode `y` pushes a selection back out to the OS clipboard
- Cursor-shape (DECSCUSR) passthrough so vim's insert-mode cursor renders correctly through tmux

**vim (`.vimrc`)**
- 4-space indentation, no backup/swap files, autoread
- Yank bridges: yanking in vim pushes to both tmux's paste buffer and the Windows clipboard
- Paste bridge: `p`/`P` pull from the Windows clipboard first, so paste always has the latest system-clipboard content
- Cursor shape changes between normal and insert mode

**Other**
- `.gitattributes` forces LF line endings, since the repo moves between Windows and Linux
