#!/bin/bash
clear
b=$(tput bold 2>/dev/null)
n=$(tput sgr0 2>/dev/null)
cat <<EOF
${b}tmux shortcuts${n}  (prefix Alt+q)

${b}Misc${n}
 r        Reload config
 T        Set pane label
 ?        Show this help

${b}Pane${n}
 | / -    Split horizontal / vertical
 = / +    Even layout: horiz / vert
 x        Close pane
 o        Cycle to next pane
 q        Show pane numbers
 Alt+h/l  Switch pane left / right
 Alt+j/k  Switch pane up / down
 [        Enter copy mode
  v         begin selection
  y         copy & exit
 p / ]    Paste buffer (from machine clipboard)

${b}Window${n}
 c        New window
 n        Next window
 l        Last window
 0-9      Jump to window N
 w        List windows
 ,        Rename window
 &        Close window

${b}Session${n}
 d        Detach client
 s        List sessions
 \$        Rename session

     Esc to close
EOF
while IFS= read -rsn1 key; do
    [ "$key" = $'\x1b' ] && break
done
