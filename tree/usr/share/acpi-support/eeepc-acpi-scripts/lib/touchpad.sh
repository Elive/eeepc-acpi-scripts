# a shell library for handling touchpad toggling
#
# to be sourced

getXconsole

toggle_touchpad()
{
    local STATE
    STATE="$(synclient -l 2>/dev/null | sed -e '/TouchpadOff/! d; s/[^0-9]\+//g')"
    synclient TouchpadOff=$((1-STATE)) 2>/dev/null || return 2
    return $((1-STATE))
}
