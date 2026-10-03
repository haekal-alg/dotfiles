#!/bin/bash
# OS clipboard bridge shared by .tmux.conf and .vimrc:
#   clip.sh copy        stdin -> OS clipboard
#   clip.sh paste       OS clipboard -> stdout (exit 1 if no reader found)
#   clip.sh tmux-paste  OS clipboard -> tmux buffer -> current pane
# Kept in one script so the per-OS branching lives in one place, instead of
# if-shell blocks repeated per key in .tmux.conf plus WSL-only guards in
# .vimrc (which left vim with no system clipboard at all off WSL).

copy=()
paste=()

# WSL first: it also passes every plain-Linux check below, and can have xclip
# installed with no X server behind it.
if uname -r | grep -qi microsoft; then
  # win32yank.exe must live on the NTFS-backed /mnt/c filesystem, not the
  # WSL/ext4 side (~/.local/bin) -- launched via WSL interop from an ext4
  # path it fails clipboard access with OS error 5 (no window-station
  # attachment); from /mnt/c it's reliable. Globbed instead of a hardcoded
  # /mnt/c/Users/<name>/... so the Windows account name stays out of this
  # file. clip.exe is the write-only fallback; there's no read fallback
  # because the PowerShell Get-Clipboard round-trip proved unreliable.
  w=$(ls /mnt/c/Users/*/.local/bin/win32yank.exe 2>/dev/null | head -1)
  if [ -n "$w" ]; then
    copy=("$w" -i --crlf)
    paste=("$w" -o --lf)
  else
    copy=(clip.exe)
  fi
elif [ "$(uname -s)" = Darwin ]; then
  copy=(pbcopy)
  paste=(pbpaste)
elif [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null 2>&1; then
  copy=(wl-copy)
  paste=(wl-paste --no-newline)
elif command -v xclip >/dev/null 2>&1; then
  copy=(xclip -in -selection clipboard)
  paste=(xclip -out -selection clipboard)
elif command -v xsel >/dev/null 2>&1; then
  copy=(xsel --clipboard --input)
  paste=(xsel --clipboard --output)
fi

case "$1" in
  copy)
    [ ${#copy[@]} -gt 0 ] || exit 1
    # stdout to /dev/null: xclip/wl-copy fork a background process that owns
    # the selection and inherits stdout, so tmux's copy-pipe and vim's
    # system() would otherwise wait on that pipe and hang.
    "${copy[@]}" >/dev/null
    ;;
  paste)
    [ ${#paste[@]} -gt 0 ] || exit 1
    "${paste[@]}"
    ;;
  tmux-paste)
    # run-shell inherits the tmux SERVER's PATH, not the interactive shell's.
    # On the WSL box bare `tmux` resolves to an old /usr/bin/tmux ahead of the
    # custom build in ~/.local/bin that's actually running the server; on
    # machines without that build, PATH lookup is fine.
    t=~/.local/bin/tmux
    [ -x "$t" ] || t=tmux
    # No reader -> skip the load and paste tmux's own buffer, so the key
    # still does something rather than nothing.
    if [ ${#paste[@]} -gt 0 ]; then
      "${paste[@]}" | "$t" load-buffer -
    fi
    "$t" paste-buffer
    ;;
  *)
    echo "usage: ${0##*/} copy|paste|tmux-paste" >&2
    exit 2
    ;;
esac
