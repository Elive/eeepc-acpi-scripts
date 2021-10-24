#!/bin/sh

[ -d /sys/devices/platform/eeepc ] || [ -d /sys/devices/platform/eeepc-wmi ] || exit 0
PKG=eeepc-acpi-scripts
PKG_DIR=/usr/share/acpi-support/$PKG
FUNC_LIB=$PKG_DIR/lib/functions.sh

. $FUNC_LIB

# first try kernel rfkill
detect_rfkill wwan

if [ -n "$RFKILL" ]; then
    if have_dev_rfkill; then
	gsm_control=wwan
    elif echo `cat $RFKILL` > $RFKILL 2> /dev/null; then
        gsm_control="$RFKILL"
    fi

    get_gsm_rfkill ()
    {
	get_rfkill "$RFKILL"
    }

    set_gsm_rfkill ()
    {
	set_rfkill "$RFKILL" "$1"
    }
fi

# then try USB
if [ -z "$gsm_control" ]; then
    for f in /sys/bus/usb/devices/*; do
	if [ -f "$f/product" ] && grep -q '^HUAWEI Mobile' $f/product; then
            gsm_control="$f/power/level"
            gsm_on=auto
            gsm_off=suspend
            break
	fi
    done

    get_gsm_rfkill ()
    {
	[ `cat "$gsm_control"` != "$gsm_off" ] && echo 1 || echo 0
    }

    set_gsm_rfkill ()
    {
	if [ "$1" = 1 ]; then
            echo "$gsm_off" > "$gsm_control"
        else
            echo "$gsm_on" > "$gsm_control"
        fi
    }
fi

# give up if no method to toggle GSM was found
if [ -z "$gsm_control" ]; then
    echo "GSM control not found."
    exit 1
fi

STATE="$(get_gsm_rfkill)"

case "$1" in
    detect)
	exit "$STATE"
	;;
    toggle)
	set_gsm_rfkill $((1-$STATE))
        ;;
    on|enable|1)
	set_gsm_rfkill 1
	;;
    off|disable|0)
	set_gsm_rfkill 0
	;;
    *)
	echo "Usage: $0 [on|off|detect|toggle]"
	exit 1
	;;
esac

