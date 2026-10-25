#!/bin/sh
# Installs the sudoers rule behind keepAwake's "Keep awake with lid closed" mode.
#   render <user>    print the rule (no root needed)
#   install <user>   validate it with visudo and install it (run as root)
#   uninstall        turn the override off and remove the rule (run as root)
# The rule allows exactly two commands without a password:
#   pmset -a disablesleep 1   and   pmset -a disablesleep 0
set -eu

SUDOERS_FILE=/etc/sudoers.d/keepawake

die() {
    echo "lid-sleep-helper: $*" >&2
    exit 64
}

check_user() {
    # Only plain account names: nothing that could change the meaning of the rule.
    case "${1:-}" in
        "" | -* | .* | *[!A-Za-z0-9._-]*) die "invalid user name" ;;
    esac
}

render() {
    check_user "${1:-}"
    echo "# Installed by keepAwake. Remove with: sudo rm $SUDOERS_FILE"
    echo "$1 ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0"
}

case "${1:-}" in
    render)
        render "${2:-}"
        ;;
    install)
        render "${2:-}" >/dev/null
        tmp="$(/usr/bin/mktemp)"
        trap '/bin/rm -f "$tmp"' EXIT
        render "$2" >"$tmp"
        /usr/sbin/visudo -cf "$tmp" >/dev/null
        /usr/bin/install -m 0440 -o root -g wheel "$tmp" "$SUDOERS_FILE"
        ;;
    uninstall)
        /usr/bin/pmset -a disablesleep 0
        /bin/rm -f "$SUDOERS_FILE"
        ;;
    *)
        die "usage: $0 render|install <user> | uninstall"
        ;;
esac
