#!/bin/bash
# Jump-list helper for Icon Pager context menu.
#   jumplist.sh list   <launcherUrl>            -> prints "actionId<TAB>Name" per line
#   jumplist.sh launch <launcherUrl> <actionId> -> runs that action's Exec
#
# launcherUrl comes from TasksModel LauncherUrlWithoutIcon, e.g.
#   file:///usr/share/applications/firefox.desktop
#   applications:firefox.desktop
#   /usr/share/applications/firefox.desktop

mode="$1"
url="$2"
action="$3"

resolve() {
    case "$1" in
        file://*) printf '%s' "${1#file://}" ;;
        applications:*)
            find "$HOME/.local/share/applications" \
                 /usr/share/applications \
                 /usr/local/share/applications \
                 -name "${1#applications:}" 2>/dev/null | head -n1 ;;
        /*) printf '%s' "$1" ;;
        *) : ;;
    esac
}

p="$(resolve "$url")"
[ -z "$p" ] || [ ! -f "$p" ] && exit 0

case "$mode" in
    list)
        acts="$(grep -m1 '^Actions=' "$p" | cut -d= -f2- | tr ';' ' ')"
        for a in $acts; do
            name="$(awk -v s="[Desktop Action $a]" '
                $0==s {f=1; next}
                /^\[/ {f=0}
                f && /^Name=/ {sub(/^Name=/,""); print; exit}
            ' "$p")"
            [ -n "$name" ] && printf '%s\t%s\n' "$a" "$name"
        done
        ;;
    launch)
        ex="$(awk -v s="[Desktop Action $action]" '
            $0==s {f=1; next}
            /^\[/ {f=0}
            f && /^Exec=/ {sub(/^Exec=/,""); print; exit}
        ' "$p")"
        # strip desktop-entry field codes (%u %f %F ...)
        ex="$(printf '%s' "$ex" | sed -E 's/%[fFuUdDnNickvm]//g')"
        [ -n "$ex" ] && setsid sh -c "$ex" >/dev/null 2>&1 &
        ;;
esac
exit 0
