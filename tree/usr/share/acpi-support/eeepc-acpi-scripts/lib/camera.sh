# shell library for handling builtin cameera of Assu EeePC
#
# to be sourced

CAM_CTL=/sys/devices/platform/eeepc/camera
[ -e "$CAM_CTL" ] || CAM_CTL=/proc/acpi/asus/camera #pre-2.6.26
# check if camera is enabled and return success (exit code 0 if it is
# return failure (exit code 1) if it is not
#
# uses the acpi platform driver interface if that is available
# if not, assume there is not camera and return false
camera_is_on()
{
    if [ -e "$CAM_CTL" ]; then
        [ $( cat $CAM_CTL ) = "1" ]
    else
        false
    fi
}

toggle_camera()
{
    if camera_is_on; then
        echo 0 > $CAM_CTL
    else
        if [ -e "$CAM_CTL" ]; then
            echo 1 > $CAM_CTL
        fi
    fi
}

