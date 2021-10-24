# Parse amixer output for a regexp (first parameter).
# Some controls are blacklisted; for this, we use a set of fixed strings in
# /etc/acpi/eeepc-amixer-blacklist. (No wildcards or regexps.)

PKG=eeepc-acpi-scripts
DEFAULT=/etc/default/$PKG
SOUND_FILE=/run/$PKG.sound
AMIXER=/usr/bin/amixer

[ -e "$SOUND_FILE" ] && . "$SOUND_FILE"
[ -e "$DEFAULT" ] && . "$DEFAULT"
[ -x "$AMIXER" ] || exit 1

[ "$SOUND_LABEL" = '' ] && SOUND_LABEL="$DEF_SOUND_LABEL"
[ "$SOUND_SWITCH" = '' ] && SOUND_SWITCH="$DEF_SOUND_SWITCH"
[ "$SOUND_SWITCH_EXCLUSIVE" = '' ] && SOUND_SWITCH_EXCLUSIVE="$DEF_SOUND_SWITCH_EXCLUSIVE"
[ "$SOUND_VOLUME_STEP" = '' ] && SOUND_VOLUME_STEP="$DEF_SOUND_VOLUME_STEP"

configureSoundFilter() {
  grep -B1 "$1" |
  sed -r "s/^(.*'([^']+)'.*|[^']+())$/\\2/; /^$/ d" |
  if [ "$2" = '' ]; then
    grep ^Master
  else
    grep -ivF "$(sed -nre "/^#/ d; /!/! {p; d}; /!(.*,)?\b$2\b/ d; s/\s*!.*//; p" /etc/acpi/eeepc-amixer-blacklist)"
  fi
}

# Defaults
configureSound() {
    local amixer
    amixer="$($AMIXER)"

    [ "$SOUND_PREFER_MASTER" != "yes" ] || {
	[ "$SOUND_LABEL" ] || {
	    SOUND_LABEL="$(echo "$amixer" | configureSoundFilter pvolume)"
	}

	[ "$SOUND_SWITCH" ] || {
	    SOUND_SWITCH="$(echo "$amixer" | configureSoundFilter pswitch)"
	}

	[ "$SOUND_SWITCH_EXCLUSIVE" ] || {
	    SOUND_SWITCH_EXCLUSIVE="$(echo "$amixer" | configureSoundFilter ': pswitch$')"
	}
    }

    [ "$SOUND_LABEL" ] || {
	 SOUND_LABEL="$(echo "$amixer" | configureSoundFilter pvolume volume)"
    }

    [ "$SOUND_SWITCH" ] || {
	 SOUND_SWITCH="$(echo "$amixer" | configureSoundFilter pswitch mute)"
    }

    [ "$SOUND_SWITCH_EXCLUSIVE" ] || {
	 SOUND_SWITCH_EXCLUSIVE="$(echo "$amixer" | configureSoundFilter ': pswitch$' mute)"
    }

    [ "$SOUND_VOLUME_STEP" ] || {
	 case "$(grep ^00-00 /proc/asound/pcm 2>/dev/null)" in
#	     *ALC269*|*ALC662*)
#			SOUND_VOLUME_STEP=3.125%; ;;
	     *)		SOUND_VOLUME_STEP=3.125%; ;;
	 esac
    }

}
