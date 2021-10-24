#!/bin/sh
[ -d /sys/devices/platform/eeepc-wmi ] || exit 0
case $2 in
    WLAN)
        hotkey=00000010
        ;;
    PROG1)
        hotkey=00000012
        ;;
    MUTE)
        hotkey=00000013
        ;;
    VOLDN)
        hotkey=00000014
        ;;
    VOLUP)
        hotkey=00000015
        ;;
    SCRNLCK)
        hotkey=0000001a
        ;;
    VMOD)
        hotkey=00000030
        ;;
    ZOOM)
        hotkey=00000038
        ;;
esac
/usr/share/acpi-support/eeepc-acpi-scripts/hotkey.sh hotkey ASUS010:00 $hotkey $4
