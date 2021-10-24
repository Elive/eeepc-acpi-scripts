#!/bin/sh

[ -d /sys/devices/platform/eeepc ] || [ -d /sys/devices/platform/eeepc-wmi ] || exit 0
# Volume controls

# do nothing if package is removed
PKG=eeepc-acpi-scripts
PKG_DIR=/usr/share/acpi-support/$PKG
FUNC_LIB=$PKG_DIR/lib/functions.sh
DEFAULT=/etc/default/$PKG
[ -e "$FUNC_LIB" ] || exit 0

. $FUNC_LIB
. $PKG_DIR/lib/sound.sh
action=$1

usage() {
    cat <<EOF >&2
Usage: $0 up|down|toggle
EOF
    exit 1
}

configureSound

show_muteness() {
    local label msg status all_equal=1 current
    for label in $SOUND_SWITCH; do
	current=$($AMIXER get $label |
		    sed -n 's/.*\[\(on\|off\)\].*/\1/;ta;d;:a;p')
	case "$(echo "$current")" in
	    on*off*) current='on[L]'; ;;
	    off*on*) current='on[R]'; ;;
	    on*)     current='on'; ;;
	    off*)    current='off'; ;;
	esac
	[ "$status" ] || status="$current"
	[ "$status" = "$current" ] || all_equal=
	msg="$msg $current ($label)"
    done
    if [ "$all_equal" ]; then
	msg=" $status"
    fi
}

show_volume() {
    local label msg percent all_equal=1 current
    for label in $SOUND_LABEL; do
	current=$($AMIXER get $label |
		    sed -n '/%/{s/.*\[\(.*\)%\].*/\1/p;q}')
	[ "$percent" ] || percent="$current"
	[ "$percent" = "$current" ] || all_equal=
	msg="$msg $current% ($label)"
	if [ "$DETAILED_SOUND_INFO" != 'yes' ]; then
	    break
	fi
    done
    if [ "$all_equal" ]; then
	msg="$percent%"
    fi
}

# cope with control names which contain spaces
IFS='
'

case "$action" in
    toggle)
        for label in $SOUND_SWITCH; do
            $AMIXER -q set $label toggle
        done
        show_muteness
        ;;
    down)
        for label in $SOUND_LABEL $SOUND_SWITCH_EXCLUSIVE; do
            $AMIXER -q set $label "$SOUND_VOLUME_STEP"- unmute
        done
        # in case something was unmuted, make sure everything else is
        for label in $SOUND_SWITCH; do
            $AMIXER -q set $label unmute
        done
        show_volume
        ;;
    up)
        for label in $SOUND_LABEL $SOUND_SWITCH_EXCLUSIVE; do
            $AMIXER -q set $label "$SOUND_VOLUME_STEP"+ unmute
        done
        # in case something was unmuted, make sure everything else is
        for label in $SOUND_SWITCH; do
            $AMIXER -q set $label unmute
        done
        show_volume
        ;;
    *)
        usage
        ;;
esac
