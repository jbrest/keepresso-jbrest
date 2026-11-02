#!/bin/zsh
# Runs on the MacBook. Walks jbrest through hands-on sittings with timers and
# records a timestamped mark for every step. Usage:
#   zsh ~/laptop-runner.zsh preflight
#   zsh ~/laptop-runner.zsh 1      (SSH channel)
#   zsh ~/laptop-runner.zsh 2      (Screen Sharing and console sessions)
# Sittings 3 and 4 are deliberately absent until Claude Code reviews them.
set -u

STUDIO_HOST=Jeremys-Mac-Studio.local
STUDIO=jeremybrest@$STUDIO_HOST
REMOTE=dev/keepresso-jbrest/tools/hands-on/hands-on.sh
HOLD=30
# Every test connection is its own TCP connection: no multiplexing, no
# keepalives from the client side, never a password prompt unless asked.
SSH_OPTS=(-o ControlMaster=no -o ControlPath=none -o ServerAliveInterval=0
          -o BatchMode=yes -o ConnectTimeout=10)

sitting=${1:-}
stamp=$(date -u +%Y%m%dT%H%M%SZ)
marks_dir=$HOME/sh-handson-marks
mkdir -p "$marks_dir"
marks=$marks_dir/sitting$sitting-$stamp.jsonl
wifi_dev=""
wifi_turned_off=no

say()  { print -P "%B$*%b"; }
note() { print "  $*"; }

mark() {
    local step=$1; shift
    printf '{"kind":"mark","step":"%s","event":"%s","time":"%s"}\n' \
        "$step" "$*" "$(date -u +%Y-%m-%dT%H:%M:%S.000000+00:00)" >> "$marks"
    print -P "%F{cyan}[$(date +%H:%M:%S)] mark $step: $*%f"
}

countdown() {
    local seconds=$1 label=${2:-waiting}
    while (( seconds > 0 )); do
        printf '\r  %s: %3ds left ' "$label" "$seconds"
        sleep 1
        (( seconds-- ))
    done
    printf '\r  %s: done            \n' "$label"
}

wait_return() {
    print -nP "%F{yellow}  >> $* Then press Return.%f "
    read -r _
}

studio() { ssh "${SSH_OPTS[@]}" "$STUDIO" "$@"; }

studio_status() {
    mark "$1" "status check (opens one short SSH connection)"
    studio "sh $REMOTE status" || note "(status check failed; carry on)"
}

restore_wifi() {
    if [[ $wifi_turned_off == yes && -n $wifi_dev ]]; then
        networksetup -setairportpower "$wifi_dev" on
        print "  Wi-Fi turned back on."
        wifi_turned_off=no
    fi
}

cleanup() {
    restore_wifi
    jobs -p | while read -r pid; do kill "$pid" 2>/dev/null; done
}
trap cleanup EXIT
trap 'print "\nStopped early. Your marks so far: $marks"; exit 130' INT

# Keep the laptop awake while this runs, and only while this runs.
caffeinate -dims -w $$ &!

find_wifi() {
    wifi_dev=$(networksetup -listallhardwareports |
        awk '/Hardware Port: Wi-Fi/{getline; print $2}')
}

finish() {
    mark "$1" "sitting finished"
    if scp -q -o ControlMaster=no -o ControlPath=none -o BatchMode=yes \
        "$marks" "$STUDIO:sh-handson-captures/"; then
        say "Done. Marks copied to the Studio (~/sh-handson-captures/)."
    else
        say "Done, but copying the marks failed. They are in $marks"
    fi
}

preflight() {
    say "Preflight (about 1 minute, changes nothing)"
    if studio true; then note "SSH with your key: ok"; else
        note "SSH with your key FAILED. Tell Claude; don't run the sittings."; exit 1; fi
    if [[ $(studio "sh $REMOTE check" 2>/dev/null) == ok ]]; then
        note "Studio recorder and tmux: ok"
    else
        note "Studio recorder check FAILED. Tell Claude."; exit 1
    fi
    local offset=$(( $(studio 'date +%s') - $(date +%s) ))
    note "Clock difference Studio minus laptop: ${offset}s (fine if within 2)"
    find_wifi
    local route_if=$(route -n get "$STUDIO_HOST" 2>/dev/null | awk '/interface:/{print $2}')
    note "Laptop Wi-Fi device: ${wifi_dev:-none}; route to the Studio uses: ${route_if:-unknown}"
    if [[ -n $wifi_dev && $route_if == "$wifi_dev" ]]; then
        note "Step 1.8 can switch Wi-Fi off and on by itself: ok"
    else
        note "Step 1.8 will ask you to disconnect by hand (laptop is not on Wi-Fi only)."
    fi
    say "Preflight passed."
}

sitting1() {
    say "Sitting 1: SSH channel (about 35 minutes of steps, then the recorder keeps going)"
    note "Stay connected to the Studio by Screen Sharing if you like; it doesn't affect this."
    note "Don't open any other SSH, sftp or VS Code Remote connection to the Studio until the end."
    wait_return "Ready?"
    mark 1.start "starting the recorder (one short SSH connection)"
    studio "sh $REMOTE start sitting1 keep-awake" || { note "Could not start the recorder."; exit 1; }
    countdown 60 "letting that setup connection disappear"

    mark 1.0 "baseline, nothing connected"
    countdown 60 "baseline"

    mark 1.1 "nc to port 22 opened (never authenticates)"
    nc "$STUDIO_HOST" 22 > /dev/null &
    local pid=$!
    countdown $HOLD "holding"
    kill $pid 2>/dev/null; wait $pid 2>/dev/null
    mark 1.1 "nc closed"
    countdown $HOLD "settling"

    mark 1.2 "ssh at the password prompt (no password is ever sent)"
    local askpass=$(mktemp -t sh-askpass)
    print '#!/bin/sh\nsleep 30\nexit 1' > "$askpass"; chmod 700 "$askpass"
    local started=$SECONDS
    SSH_ASKPASS=$askpass SSH_ASKPASS_REQUIRE=force ssh -o ControlMaster=no -o ControlPath=none \
        -o PubkeyAuthentication=no -o PreferredAuthentications=keyboard-interactive,password \
        -o NumberOfPasswordPrompts=1 -o ConnectTimeout=10 "$STUDIO" true < /dev/null 2>/dev/null
    rm -f "$askpass"
    if (( SECONDS - started < 20 )); then
        mark 1.2 "ended early: the Studio offered no password prompt"
    else
        mark 1.2 "prompt abandoned after 30s"
    fi
    countdown $HOLD "settling"

    mark 1.3 "interactive-style session with a terminal"
    studio -tt 'sleep 30' > /dev/null 2>&1
    mark 1.3 "session exited cleanly"
    countdown $HOLD "settling"

    mark 1.4 "ssh -N (authenticated, no shell)"
    studio -N &
    pid=$!
    countdown $HOLD "holding"
    kill $pid 2>/dev/null; wait $pid 2>/dev/null
    mark 1.4 "closed"
    countdown $HOLD "settling"

    mark 1.5 "command without a terminal: sleep 45"
    studio -T 'sleep 45'
    mark 1.5 "command finished"
    countdown $HOLD "settling"

    mark 1.6 "two terminal sessions opened"
    studio -tt 'sleep 600' < /dev/null > /dev/null 2>&1 &
    local first=$!
    studio -tt 'sleep 600' < /dev/null > /dev/null 2>&1 &
    local second=$!
    countdown $HOLD "holding both"
    kill $first 2>/dev/null; wait $first 2>/dev/null
    mark 1.6 "first closed, second still open"
    countdown $HOLD "holding one"
    kill $second 2>/dev/null; wait $second 2>/dev/null
    mark 1.6 "second closed"
    countdown $HOLD "settling"

    mark 1.7 "sftp session"
    printf 'pwd\n!sleep %s\nbye\n' $HOLD |
        sftp -q -o ControlMaster=no -o ControlPath=none -o BatchMode=yes -b - "$STUDIO" > /dev/null
    mark 1.7 "sftp closed"
    countdown $HOLD "settling"

    say "Step 1.8: dirty disconnect. Wi-Fi goes off for 5 minutes."
    note "Screen Sharing will drop. Ignore it; this script keeps running."
    find_wifi
    local route_if=$(route -n get "$STUDIO_HOST" 2>/dev/null | awk '/interface:/{print $2}')
    mark 1.8 "long session opened (remote sleep 3h stands in for an idle shell)"
    studio -tt 'sleep 10800' < /dev/null > /dev/null 2>&1 &
    pid=$!
    countdown $HOLD "holding"
    if [[ -n $wifi_dev && $route_if == "$wifi_dev" ]]; then
        networksetup -setairportpower "$wifi_dev" off && wifi_turned_off=yes
    fi
    if [[ $wifi_turned_off != yes ]]; then
        wait_return "Disconnect the laptop from the network by hand now (Wi-Fi off, unplug Ethernet)."
    fi
    mark 1.8 "laptop offline"
    countdown 20 "offline"
    # Killed while offline, so the Studio never hears the connection close.
    kill -9 $pid 2>/dev/null; wait $pid 2>/dev/null
    mark 1.8 "client killed while offline"
    countdown 260 "staying offline"
    if [[ $wifi_turned_off == yes ]]; then
        restore_wifi
    else
        wait_return "Reconnect the laptop to the network."
    fi
    mark 1.8 "laptop back online"
    countdown 90 "waiting for the network to settle"
    studio_status 1.8
    note "Any 'other SSH processes' above are the dead session lingering on the Studio."
    note "The recorder keeps watching for up to 4 hours and keeps the Studio awake meanwhile."
    finish 1.end
    note "Leave the recorder running. Tell Claude when you want it stopped and read."
}

sitting2() {
    say "Sitting 2: Screen Sharing and console sessions (about 40 minutes)"
    note "You need: Screen Sharing on this laptop connected to the Studio as jeremybrest,"
    note "the shtest account and its password, and Fast User Switching in the Studio's menu bar."
    wait_return "Connected by Screen Sharing as jeremybrest?"
    mark 2.start "starting the recorder"
    studio "sh $REMOTE start sitting2" || { note "Could not start the recorder."; exit 1; }

    mark 2.0 "baseline: Screen Sharing connected as jeremybrest"
    countdown 60 "baseline"
    studio_status 2.0

    wait_return "2.1: Quit Screen Sharing on this laptop (Cmd-Q)."
    mark 2.1 "Screen Sharing quit"
    countdown $HOLD "disconnected"
    studio_status 2.1
    note "Watch whether screensharingd and coreaudiod (for avconferenced) are gone from the sleep blocks."
    countdown 90 "staying disconnected"
    wait_return "Reconnect Screen Sharing as jeremybrest."
    mark 2.1 "reconnected"
    countdown $HOLD "holding"

    wait_return "2.2: In the Studio window, lock the screen with Ctrl-Cmd-Q."
    mark 2.2 "locked"
    countdown $HOLD "holding"
    wait_return "Quit Screen Sharing (Cmd-Q)."
    mark 2.2 "locked and disconnected"
    countdown 60 "disconnected"
    studio_status 2.2
    countdown 60 "disconnected"
    wait_return "Reconnect Screen Sharing and unlock with jeremybrest's password."
    mark 2.2 "reconnected and unlocked"
    countdown $HOLD "holding"

    wait_return "2.3: In the Studio's menu bar, click the user switcher (your name or a person icon) and choose Login Window."
    mark 2.3 "login window, jeremybrest still logged in"
    countdown 60 "at the login window"
    studio_status 2.3
    wait_return "Log back in as jeremybrest at the login window."
    mark 2.3 "back as jeremybrest"
    countdown $HOLD "holding"

    wait_return "2.4: User switcher > shtest, enter its password, finish any first-login setup screens until you see shtest's desktop."
    mark 2.4 "shtest on screen, jeremybrest logged in behind"
    countdown $HOLD "holding"
    studio_status 2.4
    wait_return "User switcher > jeremybrest, enter your password."
    mark 2.4 "back as jeremybrest, shtest logged in behind"
    countdown $HOLD "holding"

    wait_return "2.5: User switcher > shtest, then Apple menu > Log Out shtest. At the login window, click jeremybrest and log in."
    mark 2.5 "shtest logged out, back as jeremybrest"
    countdown $HOLD "holding"
    studio_status 2.5

    note "2.6: a second, separate Screen Sharing session as shtest."
    note "In Screen Sharing on this laptop: File > New (or Connect), Jeremys-Mac-Studio.local,"
    note "sign in as shtest. If it asks, choose to log in as yourself (a separate session)."
    wait_return "Do that, and stop when you see shtest's desktop in the new window."
    mark 2.6 "shtest virtual session open alongside jeremybrest"
    countdown $HOLD "holding"
    studio_status 2.6

    wait_return "2.7: Close only the shtest window (Cmd-W), without logging out shtest."
    mark 2.7 "shtest window closed, not logged out"
    countdown 60 "waiting"
    studio_status 2.7
    countdown 60 "waiting"

    wait_return "2.8: Connect again as shtest, then Apple menu > Log Out in that window."
    mark 2.8 "shtest virtual session logged out"
    countdown $HOLD "holding"
    studio_status 2.8

    wait_return "2.9: In jeremybrest's window: System Settings > Users & Groups > shtest (i) > Delete User, choose Delete the home folder."
    mark 2.9 "shtest deleted"
    countdown $HOLD "holding"
    studio_status 2.9
    studio "sh $REMOTE stop"
    finish 2.end
}

case $sitting in
preflight) preflight ;;
1) preflight && sitting1 ;;
2) preflight && sitting2 ;;
*) print "usage: zsh $0 preflight | 1 | 2"; exit 2 ;;
esac
