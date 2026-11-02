#!/bin/sh
# Studio-side control for the hands-on recorder. Read-only toward the system,
# except that "start LABEL keep-awake" also holds a labeled caffeinate
# assertion for as long as the recorder runs.
#   hands-on.sh start LABEL [keep-awake]   record in a detached tmux session
#   hands-on.sh status                     live summary (ignores its own SSH)
#   hands-on.sh stop                       stop recording, print the capture
#   hands-on.sh check                      preflight: prints "ok" if usable
set -eu

here=$(cd "$(dirname "$0")" && pwd)
captures="$HOME/sh-handson-captures"
session="sh-record"
tmux=/opt/homebrew/bin/tmux

mkdir -p "$captures"

stop_recording() {
    if "$tmux" has-session -t "$session" 2>/dev/null; then
        "$tmux" kill-session -t "$session"
        sleep 1
        echo "Stopped recording. Capture: $(readlink "$captures/current.jsonl")"
    else
        echo "No recording was running."
    fi
}

case "${1:-}" in
start)
    label=${2:?usage: hands-on.sh start LABEL [keep-awake]}
    if "$tmux" has-session -t "$session" 2>/dev/null; then
        stop_recording
    fi
    out="$captures/$label-$(date -u +%Y%m%dT%H%M%SZ).jsonl"
    ln -sf "$out" "$captures/current.jsonl"
    command="/usr/bin/python3 '$here/record.py' --label '$label' --out '$out' --max-hours 4"
    if [ "${3:-}" = "keep-awake" ]; then
        # Ends with the recorder. Shows in captures as caffeinate's assertion.
        command="/usr/bin/caffeinate -i $command"
    fi
    "$tmux" new-session -d -s "$session" "$command"
    sleep 3
    "$tmux" has-session -t "$session" 2>/dev/null || { echo "Recorder failed to start." >&2; exit 1; }
    echo "Recording to $out"
    ;;
status)
    running=no
    "$tmux" has-session -t "$session" 2>/dev/null && running=yes
    echo "  recorder running: $running"
    /usr/bin/python3 "$here/record.py" --status
    ;;
stop)
    stop_recording
    ;;
check)
    [ -x "$tmux" ] && /usr/bin/python3 "$here/record.py" --status >/dev/null && echo ok
    ;;
*)
    echo "usage: hands-on.sh start LABEL [keep-awake] | status | stop | check" >&2
    exit 2
    ;;
esac
