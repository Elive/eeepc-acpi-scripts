# a shell library for handling Asus EeePC "Super Hybrid Engine"
#
# to be sourced
# requires that the defaults file has been sourced

SHENGINE_CTL=/sys/devices/platform/eeepc/cpufv
SHENGINE_LIMIT="$(cat "$SHENGINE_CTL" 2>/dev/null || :)"
SHENGINE_LIMIT=$(( ${SHENGINE_LIMIT:-768} >> 8 ))

SHENGINE_CONFIG=/var/lib/eeepc-acpi-scripts/cpufv
SHENGINE_SETTING="$(cat "$SHENGINE_CONFIG" 2>/dev/null || :)"
SHENGINE_SETTING=${SHENGINE_SETTING:-$DEFAULT_SHENGINE_CONFIG}

get_shengine()
{
    if [ "${SHENGINE_SETTING:-auto}" = auto -a "$1" = '' ]; then
	echo 255
    elif [ -e "$SHENGINE_CTL" ]; then
        echo $(( $(cat "$SHENGINE_CTL") & 0xFF ))
    else
	echo 3
    fi
}

set_shengine()
{
    if [ -e "$SHENGINE_CTL" -a "${SHENGINE_SETTING:-auto}" = auto ]; then
	echo "$1" > "$SHENGINE_CTL"
    fi
}

cycle_shengine()
{
    if [ -e "$SHENGINE_CTL" ]; then
	SHENGINE_CLOCKING=$(get_shengine)
	if [ "${SHENGINE_SETTING:-auto}" = auto ]; then
	    SHENGINE_CLOCKING=0
	    SHENGINE_SETTING=manual
	    echo manual >"$SHENGINE_CONFIG"
	else
	    SHENGINE_CLOCKING=$(( ($SHENGINE_CLOCKING + 1) % $SHENGINE_LIMIT))
	    if [ "$SHENGINE_CLOCKING" = 0 ]; then
		if [ "$(cat /sys/class/power_supply/AC0/online 2>/dev/null || echo 1)" != 0 ]; then
		    SHENGINE_CLOCKING="$PWR_CLOCK_AC"
		    SHENGINE_DEFAULT=0
		else
		    SHENGINE_CLOCKING="$PWR_CLOCK_BATTERY"
		    SHENGINE_DEFAULT=$(($SHENGINE_LIMIT - 1))
		fi
		if [ "$SHENGINE_CLOCKING:+1" ]; then
		    SHENGINE_SETTING=auto
		    echo auto >"$SHENGINE_CONFIG"
		fi
	    fi
	fi
	echo "${SHENGINE_CLOCKING:-$SHENGINE_DEFAULT}" > "$SHENGINE_CTL"
    fi
}

handle_shengine() {
    if [ -e "$SHENGINE_CTL" ]; then
	if [ "$1" = '' ]; then
	    cycle_shengine
	else
	    set_shengine "$1"
	fi
	if [ "$2" != '' ]; then return; fi
	case $(get_shengine) in
	    0) notify super_hybrid_engine 'S. H. Engine: Performance'; ;;
	    1) notify super_hybrid_engine 'S. H. Engine: Standard'; ;;
	    2) notify super_hybrid_engine 'S. H. Engine: Power-saving'; ;;
	    255) notify super_hybrid_engine 'S. H. Engine: Automatic'; ;;
	    *) notify error 'S. H. Engine unavailable'
	esac
    else
	notify error 'S. H. Engine unavailable'
    fi
}

shengine_supported()
{
    local model
    model=`cat /sys/class/dmi/id/product_name`

    [ "${SHENGINE_FORCE_ENABLE:-0}" = "1" ] && return 0

    # models 701 and 702 are not supported
    # see http://bugs.debian.org/559578
    ! [ "$model" = '701' -o "$model" = '702' ]
}
