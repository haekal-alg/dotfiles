" c: Automatically break comments using the textwidth value.
" r: Automatically insert the comment leader when hitting <Enter> in insert mode.
" o: Automatically insert the comment leader when hitting 'o' or 'O' in normal mode.
" n: Recognize numbered lists. When hitting <Enter> in insert mode.
" m: Automatically break the current line before inserting a new comment line.
set formatoptions+=cronm
" This sets the width of a tab character to 4 spaces.
set tabstop=4

" This sets the number of spaces used when the <Tab> key is pressed in insert
" mode to 4.
set softtabstop=4

" This sets the number of spaces used for each indentation level when using
" the '>' and '<' commands, as well as the autoindent feature.
set shiftwidth=4

" This setting enables automatic indentation, which will copy the indentation
" of the current line when starting a new line.
set autoindent

" This disables the automatic conversion of tabs to spaces when you press the
" <Tab> key.
set noexpandtab

" This enables the use of the mouse in all modes (normal, visual, insert,
" command-line, etc.).
set mouse=a

" This displays line numbers in the left margin.
set number

" This disables the creation of backup files.
set nobackup

" This disables the creation of swap files.
set noswapfile

" Automatically reload files when they change
set autoread

" Highlight the current line
set cursorline

" Set text width to 100
set textwidth=100

" Cursor shape: block in normal/visual mode, thin vertical bar in insert mode.
" Vim's termcap only exposes t_SI (enter insert) / t_SR (enter replace) /
" t_EI (leave insert, i.e. "everything else" incl. visual) — there's no
" separate code for visual, so it shares the block shape with normal mode.
" Requires tmux's terminal-overrides Ss/Se passthrough (see .tmux.conf) to
" reach the outer terminal when running inside tmux.
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[2 q"

" Prevent re-indentation cascading on every line when pasting from outside
" vim (e.g. tmux/system clipboard). NOTE: this is global, not paste-scoped —
" it also disables autoindent/expandtab/etc. while typing normally. If that
" gets annoying, swap for `set pastetoggle=<F2>` instead.
set paste

" Send yanked/deleted text into tmux's paste buffer so `prefix + p` in tmux
" pastes whatever was last put in a register in vim — bridges vim's
" registers and tmux's buffer without touching the Windows clipboard
" (clip.exe/PowerShell Get-Clipboard round-trip was tested and is unreliable
" on this machine). Covers y/d/c, not just y: TextYankPost also fires for
" delete and change (dd/cc/etc. fill the unnamed register too), and the
" pull-before-paste hook below overwrites the unnamed register from the
" Windows clipboard on every p/P — if a delete didn't reach the Windows
" clipboard here, that pull would clobber it right before pasting.
" Reads @" (unnamed), not @0: register 0 only holds the last true yank and
" is untouched by delete/change, so @0 would silently miss every dd/cc.
if exists('$TMUX')
  augroup TmuxYankBridge
    autocmd!
    autocmd TextYankPost * if v:event.operator =~# '[ydc]' | call system('tmux load-buffer -', @") | endif
  augroup END
endif

" Also push vim yanks/deletes straight to the Windows clipboard (win32yank),
" not just tmux's buffer, so a vim yank or dd is pastable in the
" browser/other Windows apps too — and so the pull-before-paste hook below
" round-trips the correct content instead of stale clipboard data. Gated on
" WSL, not $TMUX, so it works outside tmux too. Read side (paste) needs its
" own hook below since TextYankPost only fires on yank/delete/change, not put.
" NOTE: win32yank.exe must live on the NTFS-backed /mnt/c filesystem, not
" the WSL/ext4 side — launched via WSL interop from an ext4 path it fails
" clipboard access with OS error 5 (no window-station attachment); from
" /mnt/c it's reliable. Hence the absolute path instead of relying on PATH.
" Resolved via glob() instead of a hardcoded /mnt/c/Users/<name>/... —
" keeps the Windows account name out of this file and works unmodified
" on any machine.
let s:win32yank = get(glob('/mnt/c/Users/*/.local/bin/win32yank.exe', 0, 1), 0, '')
if exists('$WSL_DISTRO_NAME')
  function! s:PushWinClipboard()
    call system(s:win32yank . ' -i --crlf', @")
  endfunction
  augroup WinClipboardYankBridge
    autocmd!
    autocmd TextYankPost * if v:event.operator =~# '[ydc]' | call s:PushWinClipboard() | endif
  augroup END
endif

" Pull the Windows clipboard into the unnamed register before p/P, so
" pasting in vim gets whatever was last copied on the Windows side (e.g.
" a browser). win32yank is the read path — clip.exe is write-only and the
" PowerShell Get-Clipboard round-trip tested before this was unreliable.
if exists('$WSL_DISTRO_NAME')
  function! s:PullWinClipboard()
    let @" = system(s:win32yank . ' -o --lf')
  endfunction
  nnoremap <silent> p :call <SID>PullWinClipboard()<CR>p
  nnoremap <silent> P :call <SID>PullWinClipboard()<CR>P
endif
