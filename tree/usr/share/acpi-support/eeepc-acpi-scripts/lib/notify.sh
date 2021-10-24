# eeepc-acpi-scripts notification library
#
# this file is to be sourced

notify() {
    CATEGORY=$1
    MSG=$2
    ICON_bluetooth="bluetooth"
    ICON_super_hybrid_engine="battery"
    ICON_error="error"
    ICON_camera="camera"
    ICON_touchpad="input-touchpad"
    ICON_gsm="gsm"
    ICON_wifi="network-wireless"

    if [ -n "$4" -o \( -n "$3" -a "$3" != 'fast' \) ]; then
	echo "usage: notify 'category' 'message text' [fast]" > /dev/stderr
	return 1
    fi
    echo "$MSG"  # for /var/log/acpid

    if [ ! -S /tmp/.X11-unix/X0 ]; then
        # echo's behaviour wrt "\r" is shell-dependent
	printf "$MSG\r\n" > /dev/console
	return
    fi

    if [ "x$ENABLE_OSD" = "xno" ]; then
        return
    fi

    if [ -x /usr/bin/notify-send ]; then
	getXconsole
	eval home=~$user
	eval `grep -m 1 ^DBUS_SESSION_BUS_ADDRESS $home/.dbus/session-bus/*`
	eval ICON=\$ICON_$1
	su $user -c notify-send\ -i\ $ICON\ "$2"
    else
        echo "Please install libnotify-bin" > /dev/stderr
        return 1
    fi
}

