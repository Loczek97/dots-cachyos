#!/usr/bin/env bash

EWW=$(which eww)
CFG="$HOME/.config/eww/bar/"
FILE="$HOME/.cache/eww_launch.bar"

# Wait for eww daemon to be ready
wait_for_daemon() {
	local max_attempts=30
	local attempt=0
	
	while [ $attempt -lt $max_attempts ]; do
		if "$EWW" ping &>/dev/null; then
			return 0
		fi
		sleep 0.5
		attempt=$((attempt + 1))
	done
	
	echo "Error: eww daemon did not start after 15 seconds" >&2
	return 1
}

run_eww() {
	wait_for_daemon || exit 1
	"$EWW" --config "$CFG" open bar
}

close_eww() {
	"$EWW" --config "$CFG" close bar
}

# Check for --force-open flag
if [[ "$1" == "--force-open" ]]; then
	touch "$FILE"
	run_eww
	exit 0
fi

# Check for --force-close flag
if [[ "$1" == "--force-close" ]]; then
	close_eww
	rm -f "$FILE"
	exit 0
fi

# Normal toggle behavior
if [[ ! -f "$FILE" ]]; then
	touch "$FILE"
	run_eww
else
	close_eww
	rm "$FILE"
fi
