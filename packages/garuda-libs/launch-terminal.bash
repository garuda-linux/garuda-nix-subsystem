#!/usr/bin/bash

# See: https://gitlab.com/garuda-linux/pkgbuilds/-/blob/main/garuda-libs/launch-terminal

set -e

LAUNCH_TERMINAL_SHELL=bash

usage() {
	echo "Usage: ${0##*/} [cmd]"
	echo '    -s [shell]         Change shell to [shell]'
	echo '    -h                 This help'
	exit 1
}

opts='s:h'

while getopts "${opts}" arg; do
	case "${arg}" in
	s) LAUNCH_TERMINAL_SHELL="$OPTARG" ;;
	h | ?) usage 0 ;;
	*)
		echo "invalid argument '${arg}'"
		usage 1
		;;
	esac
done

shift $((OPTIND - 1))

initfile="$(mktemp)"
codefile="$initfile"
echo "#!/usr/bin/env bash" >"$initfile"
if [ "$LAUNCH_TERMINAL_SHELL" != "bash" ]; then
	codefile="$(mktemp)"
	echo "$LAUNCH_TERMINAL_SHELL $codefile" >>"$initfile"
fi
echo "$1" >>"$codefile"
chmod +x "$initfile"
cmd="\"$initfile\""

terminal=""
declare -A terminals=(["alacritty"]="alacritty -e $cmd || LIBGL_ALWAYS_SOFTWARE=1 alacritty -e $cmd" ["konsole"]="konsole -e $cmd" ["kgx"]="kgx -- $cmd" ["gnome-terminal"]="gnome-terminal --wait -- $cmd" ["xfce4-terminal"]="xfce4-terminal --disable-server --command '$cmd'" ["qterminal"]="qterminal -e $cmd" ["lxterminal"]="lxterminal -e $cmd" ["mate-terminal"]="mate-terminal --disable-factory -e $cmd" ["xterm"]="xterm -e $cmd")
declare -a term_order=("alacritty" "konsole" "kgx" "gnome-terminal" "mate-terminal" "xfce4-terminal" "qterminal" "lxterminal" "xterm")

case "$XDG_CURRENT_DESKTOP" in
KDE)
	terminal=konsole
	;;
GNOME)
	if command -v "kgx" &>/dev/null; then
		terminal=kgx
	else
		terminal=gnome-terminal
	fi
	;;
XFCE)
	terminal=xfce4-terminal
	;;
LXQt)
	terminal=qterminal
	;;
MATE)
	terminal=mate-terminal
	;;
esac

if [ -z "$terminal" ] || ! command -v "$terminal" &>/dev/null; then
	for i in "${term_order[@]}"; do
		if command -v "$i" &>/dev/null; then
			terminal="$i"
			break
		fi
	done
fi

if [ -z "$terminal" ]; then
    # Should never happen, xterm should always be in PATH
	exit 1
fi

# Special kgx, thanks gnome
if [ "$terminal" == "kgx" ]; then
	sed -i '2i sleep 0.1' "$initfile"
	echo "kill -SIGINT \$PPID" >>"$initfile"
fi

exitcode=0
eval "${terminals[${terminal}]}" || {
	exitcode=$?
}

rm "$initfile"
if [ "$codefile" != "$initfile" ]; then
	rm "$codefile"
fi

if [ "$exitcode" != 0 ] && [ "$exitcode" != 130 ]; then
	exit 2
fi
