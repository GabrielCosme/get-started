#!/usr/bin/env bash
# Timezone and locale.
#
# Override with:  TIMEZONE=Europe/Lisbon LOCALE=en_GB.UTF-8 ./install.sh --only locale
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

TIMEZONE="${TIMEZONE:-America/Sao_Paulo}"
LOCALE="${LOCALE:-en_US.UTF-8}"
# Generated but not made default - useful for LC_TIME/LC_MONETARY overrides.
EXTRA_LOCALES="${EXTRA_LOCALES:-pt_BR.UTF-8}"

log "Timezone"
current_tz="$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo unknown)"
if [ "$current_tz" = "$TIMEZONE" ]; then
    info "already $TIMEZONE"
elif [ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
    warn "unknown timezone '$TIMEZONE' - leaving it at $current_tz"
elif timedatectl set-timezone "$TIMEZONE" 2>/dev/null || sudo timedatectl set-timezone "$TIMEZONE" 2>/dev/null; then
    info "set to $TIMEZONE"
else
    # timedatectl needs systemd running; fall back to the files it would write.
    info "timedatectl unavailable, setting the zoneinfo link directly"
    sudo ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" | sudo tee /etc/timezone >/dev/null
    sudo dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1 || true
fi
info "local time is now: $(date)"

log "Locale"
apt_install locales

# Ubuntu ships only C.UTF-8 generated, which sorts bytewise and formats oddly.
want=("$LOCALE")
# shellcheck disable=SC2206
[ -n "$EXTRA_LOCALES" ] && want+=(${EXTRA_LOCALES//,/ })

to_gen=()
for loc in "${want[@]}"; do
    # locale -a prints e.g. "en_US.utf8" for "en_US.UTF-8"; normalise before comparing.
    norm="$(echo "$loc" | tr 'A-Z' 'a-z' | tr -d '-')"
    if locale -a 2>/dev/null | tr 'A-Z' 'a-z' | tr -d '-' | grep -qx "$norm"; then
        info "already generated: $loc"
    else
        to_gen+=("$loc")
    fi
done

if [ ${#to_gen[@]} -gt 0 ]; then
    info "generating: ${to_gen[*]}"
    for loc in "${to_gen[@]}"; do
        # Uncomment the matching line in /etc/locale.gen, adding it if absent.
        if grep -qE "^#? *${loc} " /etc/locale.gen 2>/dev/null; then
            sudo sed -i -E "s|^#? *(${loc} .*)|\1|" /etc/locale.gen
        else
            echo "${loc} ${loc##*.}" | sudo tee -a /etc/locale.gen >/dev/null
        fi
    done
    sudo locale-gen
fi

if [ "${LANG:-}" = "$LOCALE" ] && grep -q "LANG=$LOCALE" /etc/default/locale 2>/dev/null; then
    info "LANG already $LOCALE"
else
    sudo update-locale "LANG=$LOCALE" "LC_ALL="
    info "default LANG set to $LOCALE (applies to new shells)"
fi

info "current: LANG=${LANG:-unset}  ->  after re-login: LANG=$LOCALE"
