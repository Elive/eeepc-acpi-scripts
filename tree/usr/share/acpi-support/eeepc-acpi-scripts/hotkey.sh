#!/bin/sh

[ -d /sys/devices/platform/eeepc ] || [ -d /sys/devices/platform/eeepc-wmi ] || exit 0
# do nothing if package is removed
PKG=eeepc-acpi-scripts
PKG_DIR=/usr/share/acpi-support/$PKG
FUNC_LIB=$PKG_DIR/lib/functions.sh
DEFAULT=/etc/default/$PKG
[ -e "$FUNC_LIB" ] || exit 0

case $(runlevel) in
    *0|*6)
	exit 0
	;;
esac

BACKLIGHT=/sys/class/backlight/eeepc/brightness
if [ -e "$DEFAULT" ]; then . "$DEFAULT"; fi
. $FUNC_LIB

. $PKG_DIR/lib/notify.sh
code=$3
value=$(test "x$1" = x- && cat "$BACKLIGHT" || echo "0x$3")

# FIXME: should be defined in /usr/share/acpi-support/key-constants which
#   should be regenerated from a recent copy of /usr/include/linux/input.h
#   (see: #603471).
KEY_DISPLAY_OFF=245

handle_mute_toggle() {
    $PKG_DIR/volume.sh toggle
}

handle_volume_up() {
    $PKG_DIR/volume.sh up
}

handle_volume_down() {
    $PKG_DIR/volume.sh down
}

handle_blank_screen() {
    if [ -S /tmp/.X11-unix/X0 ]; then
	getXconsole

	if [ -n "$XAUTHORITY" ]; then
	    xset dpms force off
	fi
    fi
}

show_bluetooth() {
    if bluetooth_is_on; then
	notify bluetooth 'Bluetooth On'
    else
	notify bluetooth 'Bluetooth Off'
    fi
}

handle_bluetooth_toggle() {
    . $PKG_DIR/lib/bluetooth.sh
    if [ -e "$BT_CTL" ] || [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
	toggle_bluetooth
	show_bluetooth
    else
	notify error 'Bluetooth unavailable'
    fi
}

show_camera() {
    if camera_is_on; then
	notify camera 'Camera Enabled'
    else
	notify camera 'Camera Disabled'
    fi
}

handle_camera_toggle() {
    . $PKG_DIR/lib/camera.sh
    if [ -e "$CAM_CTL" ]; then
	toggle_camera
	show_camera
    else
	notify error 'Camera unavailable'
    fi
}

handle_shengine() {
    . $PKG_DIR/lib/shengine.sh
    handle_shengine "$@"
}

handle_touchpad_toggle() {
    . $PKG_DIR/lib/touchpad.sh
    toggle_touchpad
    case "$?" in
	0)
	    notify touchpad 'Touchpad on'
	    ;;
	1)
	    notify touchpad 'Touchpad off'
	    ;;
    esac
}

handle_vga_toggle() {
    $PKG_DIR/vga-toggle.sh
}

handle_gsm_toggle() {
    $PKG_DIR/gsm.sh toggle
    if $PKG_DIR/gsm.sh detect; then
        notify gsm "GSM off"
    else
        notify gsm "GSM on"
    fi
}

handle_wireless_toggle() {
    /etc/acpi/asus-wireless.sh || :
}


case $code in
    # Fn + key:
    # <700/900-series key>/<1000-series key> - function
    # "--" = not available

    # F1/F1 - suspend
    # (not a hotkey, not handled here)

    # F2/F2 - toggle wireless
    # (for kernels without rfkill input, i.e. <= 2.6.27)
    0000001[01])
	if [ "${FnF_WIRELESS}" != 'NONE' ]; then
	    ${FnF_WIRELESS:-handle_wireless_toggle}
        fi
        if /usr/sbin/rfkill list wlan | grep -q "Soft blocked: no"; then
            notify wifi "WiFi On"
        else
            notify wifi "WiFi Off"
        fi
	;;

    # --/F3 - touchpad toggle
    00000037)
	if [ "${FnF_TOUCHPAD}" != 'NONE' ]; then
	    ${FnF_TOUCHPAD:-handle_touchpad_toggle}
	fi
	;;

    # --/F4 - resolution change
    00000038) # ZOOM
	if [ "${FnF_RESCHANGE}" != 'NONE' ]; then
	    $FnF_RESCHANGE
	fi
	;;

    # --/F7 - backlight off
    00000016)
	if [ "${FnF_BACKLIGHTOFF}" != 'NONE' ]; then
	    ${FnF_BACKLIGHTOFF:-handle_blank_screen}
	fi
	;;

    # F5/F8 - toggle VGA
    0000003[012])
	if [ "${FnF_VGATOGGLE}" != 'NONE' ]; then
	    ${FnF_VGATOGGLE:-handle_vga_toggle}
	fi
	;;

    # F6/F9 - 'task manager' key
    00000012)
	if [ "${FnF_TASKMGR:-NONE}" != 'NONE' ]; then
	    $FnF_TASKMGR
	fi
	;;

    # F7/F10 - mute/unmute speakers
    00000013)
	if [ "${FnF_MUTE}" != 'NONE' ]; then
	    ${FnF_MUTE:-handle_mute_toggle}
	fi
	;;

    # F8/F11 - decrease volume
    00000014)
	if [ "${FnF_VOLUMEDOWN}" != 'NONE' ]; then
	    ${FnF_VOLUMEDOWN:-handle_volume_down}
	fi
	;;

    # F9/F12 - increase volume
    00000015)
	if [ "${FnF_VOLUMEUP}" != 'NONE' ]; then
	    ${FnF_VOLUMEUP:-handle_volume_up}
	fi
	;;

    # --/Space - SHE management
    # See "SHE button" below

    # Silver keys, left to right

    # Soft button 1
    0000001a)
	if [ "${SOFTBTN1_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN1_ACTION:-handle_blank_screen}
	fi
	;;

    # Soft button 2
    0000001b) # ZOOM
	if [ "${SOFTBTN2_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN2_ACTION}
	fi
	;;

    # Soft button 3
    0000001c)
	if [ "${SOFTBTN3_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN3_ACTION:-handle_camera_toggle}
	fi
	;;

    # Soft button 4
    0000001d)
	if [ "${SOFTBTN4_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN4_ACTION:-handle_bluetooth_toggle}
	fi
	;;

    # SHE button
    00000039)
	if [ "${SOFTBTNSHE_ACTION}" != 'NONE' ]; then
	    ${SOFTBTNSHE_ACTION:-handle_shengine}
	fi
	;;

esac
