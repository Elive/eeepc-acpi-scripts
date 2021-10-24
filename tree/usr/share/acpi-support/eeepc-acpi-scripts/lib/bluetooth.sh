# a shell library for handling Bluetooth on Asus EeePC
#
# to be sourced

detect_rfkill bluetooth
BT_CTL="$RFKILL"
if ! have_dev_rfkill; then
  [ -e "$BT_CTL" ] || BT_CTL=/sys/devices/platform/eeepc/bluetooth # pre-2.6.28
  [ -e "$BT_CTL" ] || BT_CTL=/proc/acpi/asus/bluetooth # pre-2.6.26
fi
# check if bluetooth is switched on and return success (exit code 0 if it is
# return failure (exit code 1) if it is not
#
# uses the acpi platform driver interface if that is available
# if not, uses hcitool to see if there is a hci0 device
bluetooth_is_on()
{
    if have_dev_rfkill || [ -e "$BT_CTL" ]; then
        [ $( get_rfkill "$BT_CTL" ) = "1" ]
    else
        if [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
            hcitool dev | grep -q hci0
        else
            false
        fi
    fi
}

toggle_bluetooth()
{
    if bluetooth_is_on; then
        if have_dev_rfkill || [ -e "$BT_CTL" ]; then
            set_rfkill "$BT_CTL" 0
            # udev should unload the module now
        elif [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
            hciconfig hci0 down
            rmmod hci_usb
	    for f in /sys/bus/usb/devices/*; do
		if [ -e "$f/product" ] && grep -q ^BT $f/product; then
		    echo "auto" > $f/power/level
		fi
	    done
        fi
    else
        if have_dev_rfkill || [ -e "$BT_CTL" ]; then
            set_rfkill "$BT_CTL" 1
            # udev should load the module now
        elif [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
            modprobe hci_usb
        fi
    fi
}
