#!/usr/bin/env bash

# Funkcja do wypisywania JSONa
print_workspaces() {
  spaces=$(hyprctl workspaces -j)
  active=$(hyprctl activeworkspace -j | jq '.id')
  SEQ_END=8

  echo "$spaces" | jq --argjson a "$active" --arg end "$SEQ_END" -c '
        (map( { (.id|tostring): . } ) | add) as $s
        |
        [range(1; ($end|tonumber) + 1)] | map(
            . as $i |
            (if $i == $a then "active"
             elif ($s[$i|tostring] != null and $s[$i|tostring].windows > 0) then "occupied"
             else "empty" end) as $state |

            (if $s[$i|tostring] != null then $s[$i|tostring].lastwindowtitle else "Empty" end) as $win |

            {
                id: $i,
                state: $state,
                tooltip: $win
            }
        )
    '
}

# Początkowy stan
print_workspaces

# Główna pętla z obsługą socat i brakiem buforowania
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')
fi

SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [ -S "$SOCKET_PATH" ]; then
  # stdbuf -oL wymusza wyjście liniowe (brak buforowania)
  stdbuf -oL socat -u UNIX-CONNECT:"$SOCKET_PATH" - | while read -r line; do
    case "$line" in
    workspace* | openwindow* | closewindow* | movewindow* | activewindow* | windowtitle*)
      print_workspaces
      ;;
    esac
  done
else
  # Fallback
  while true; do
    print_workspaces
    sleep 1
  done
fi
