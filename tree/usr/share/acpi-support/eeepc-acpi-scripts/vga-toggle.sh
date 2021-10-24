#!/bin/sh

[ -d /sys/devices/platform/eeepc ] || [ -d /sys/devices/platform/eeepc-wmi ] || exit 0
# do nothing if package is removed
PKG=eeepc-acpi-scripts
PKG_DIR=/usr/share/acpi-support/$PKG
FUNC_LIB=$PKG_DIR/lib/functions.sh
DEFAULT=/etc/default/$PKG
[ -e "$FUNC_LIB" ] || exit 0

if [ -e "$DEFAULT" ]; then . "$DEFAULT"; fi
. $FUNC_LIB

# return: 0 on disconnect, 1 on connected vga, 2 else
# set VGA (and LVDS) to the output name, VGA or VGA1 (LVDS or LVDS1)
getvga_status(){
    STATUSTEXT="$( xrandr -q )"
    STATUSLINE=$( echo "$STATUSTEXT" | grep ^VGA | head -n1 )
    STATUS=$( echo "$STATUSLINE" | cut -d ' ' -f 2,3 )
    VGA=$( echo "$STATUSLINE" | cut -d ' ' -f 1 )
    LVDS=$( echo "$STATUSTEXT" | grep ^LVDS | head -n1 | cut -d ' ' -f 1 )
    case "$STATUS" in
    disconnected*)
        return 0
        ;;
    connected\ \(*)
        return 1
        ;;
    *)
        return 2
        ;;
    esac
}

getXconsole
getvga_status;
# handle return value
case $? in
    1)
        xrandr --output $VGA ${VGA_ON:---auto} --output $LVDS ${LVDS_OFF:---off}
        ;;
    *)
        xrandr --output $VGA --off --output $LVDS --auto
esac

