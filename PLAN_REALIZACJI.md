# Plan optymalizacji obciążenia sprzętowego w dots-cachyos

Oto szczegółowy plan działań mający na celu znaczne zredukowanie zużycia energii, obciążenia procesora i pamięci RAM w konfiguracji `dots-cachyos`.

---

## 1. Włączenie oszczędzania energii w kompozytorze (Hyprland)

Pierwszym i najważniejszym krokiem jest przywrócenie Variable Frame Rate (VFR) w konfiguracji Hyprlanda:

> [!IMPORTANT]
> Plik: [general.lua](file:///home/michal/dotfiles/dots-cachyos/hyprland/.config/hypr/general.lua#L28-L38)
>
> - **Zmiana:** Przepisać sekcję `debug` i `misc` tak, aby VFR było włączone (`vfr = true`).

```diff
     misc = {
         force_default_wallpaper = 1,
         vrr = 0,
         disable_hyprland_logo = true,
-        disable_splash_rendering = true
+        disable_splash_rendering = true,
+        vfr = true
     },

     debug = {
-        vfr = false
+        vfr = true
     }
```

---

## 2. Drastyczna redukcja odpytywania (Polling) w QML

Obecny plik [TopBar.qml](file:///home/michal/dotfiles/dots-cachyos/quickshell/.config/quickshell/bar/TopBar.qml) generuje dziesiątki procesów na sekundę. Zoptymalizujemy to poprzez:

1. Zwiększenie interwałów (rzadsze sprawdzanie).
2. Agregację zapytań (jedno wywołanie skryptu zamiast 4 lub 8 osobnych).

### A. Optymalizacja `fastSysPoller` (Głośność i Układ klawiatury)

Obecnie wykonuje się co **150ms** i odpala `sys_info.sh` **4 razy** (łącznie spawnując subprocesy ok. 27 razy na sekundę!).

- **Zmiana 1:** Zwiększyć interwał z 150ms do **500ms** lub **1000ms** (głośność nie musi być aktualizowana 7 razy na sekundę w spoczynku).
- **Zmiana 2:** Zastąpić 4 wywołania jednym poleceniem agregującym `--all-fast`.

```diff
     Process {
         id: fastSysPoller

-        command: ["bash", "-c", `
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --volume)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --volume-icon)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --kb-layout)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --is-muted)"
-        `]
+        command: ["bash", "-c", "~/.config/quickshell/scripts/sys_info.sh --all-fast"]

         stdout: StdioCollector {
             onStreamFinished: {
                 let lines = this.text.trim().split("\n");
                 if (lines.length >= 4) {
                     barWindow.volPercent = lines[0];
                     barWindow.volIcon = lines[1];
                     barWindow.kbLayout = lines[2];
                     barWindow.isMuted = (lines[3].toLowerCase() === "true");
                 }
             }
         }
     }

     Timer {
-        interval: 150
+        interval: 500
         running: true
         repeat: true
         triggeredOnStart: true
         onTriggered: fastSysPoller.running = true
     }
```

### B. Optymalizacja `slowSysPoller` (Wi-Fi, Bluetooth, Bateria)

Obecnie odpytuje system co **1 sekundę** i odpala skrypt **8 razy**. Status baterii czy połączenia Wi-Fi nie zmienia się tak dynamicznie, by sprawdzać go co sekundę.

- **Zmiana 1:** Zwiększyć interwał z 1 sekundy do **5 sekund** (`interval: 5000`).
- **Zmiana 2:** Zastąpić 8 wywołań jednym poleceniem agregującym `--all-slow`.

```diff
     Process {
         id: slowSysPoller

-        command: ["bash", "-c", `
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --wifi-status)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --wifi-icon)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --wifi-ssid)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --bt-status)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --bt-icon)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --bt-connected)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --battery-percent)"
-            echo "$(~/.config/quickshell/scripts/sys_info.sh --battery-icon)"
-        `]
+        command: ["bash", "-c", "~/.config/quickshell/scripts/sys_info.sh --all-slow"]

         stdout: StdioCollector {
             onStreamFinished: {
                 let lines = this.text.trim().split("\n");
                 if (lines.length >= 8) {
                     barWindow.wifiStatus = lines[0];
                     barWindow.wifiIcon = lines[1];
                     barWindow.wifiSsid = lines[2];
                     barWindow.btStatus = lines[3];
                     barWindow.btIcon = lines[4];
                     barWindow.btDevice = lines[5];
                     barWindow.batPercent = lines[6];
                     barWindow.batIcon = lines[7];
                 }
             }
         }
     }

     Timer {
-        interval: 1000
+        interval: 5000
         running: true
         repeat: true
         triggeredOnStart: true
         onTriggered: slowSysPoller.running = true
     }
```

---

## 3. Implementacja agregacji w [sys_info.sh](file:///home/michal/dotfiles/dots-cachyos/quickshell/.config/quickshell/scripts/sys_info.sh)

Zamiast wielokrotnie uruchamiać ciężkie polecenia systemowe (`pamixer`, `bluetoothctl`, `nmcli`) dla każdego pojedynczego parametru, zmienimy skrypt tak, aby pobierał te dane **tylko raz** i zapisywał je do zmiennych tymczasowych.

### A. Implementacja dla `--all-fast`:

```bash
get_all_fast() {
    # 1. Pobranie danych o głośności (tylko 1 wywołanie pamixer/pactl zamiast 3!)
    local vol="50"
    local muted="false"
    if command -v pamixer &> /dev/null; then
        vol=$(pamixer --get-volume 2>/dev/null || echo "50")
        muted=$(pamixer --get-mute 2>/dev/null || echo "false")
    elif command -v pactl &> /dev/null; then
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -n1 | tr -d '%' || echo "50")
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "yes" && echo "true" || echo "false")
    fi

    # Ikona głośności
    local vol_icon="󰕾"
    if [ "$muted" = "true" ]; then vol_icon="󰝟"
    elif [ "$vol" -ge 70 ]; then vol_icon="󰕾"
    elif [ "$vol" -ge 30 ]; then vol_icon="󰖀"
    elif [ "$vol" -gt 0 ]; then vol_icon="󰕿"
    else vol_icon="󰝟"
    fi

    # 2. Pobranie układu klawiatury (1 wywołanie hyprctl)
    local layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1)
    layout=$(echo "$layout" | cut -c1-2 | tr '[:lower:]' '[:upper:]')

    # Wypisanie 4 linii
    echo "$vol"
    echo "$vol_icon"
    echo "${layout:-PL}"
    echo "$muted"
}
```

### B. Implementacja dla `--all-slow`:

```bash
get_all_slow() {
    # 1. Status sieci bezprzewodowej (1 wywołanie nmcli)
    local wifi_status="disabled"
    local wifi_ssid=""
    local wifi_icon="󰤮"

    if command -v nmcli &> /dev/null; then
        wifi_status=$(nmcli -t -f WIFI g 2>/dev/null || echo "disabled")
        if [ "$wifi_status" = "enabled" ]; then
            # Szybkie pobranie aktywnej sieci
            wifi_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep -E '^(yes|tak)' | head -1 | cut -d: -f2)
            if [ -n "$wifi_ssid" ]; then
                local strength=$(nmcli -f IN-USE,SIGNAL dev wifi 2>/dev/null | grep '^\*' | awk '{print $2}')
                strength=${strength:-0}
                if [ "$strength" -ge 75 ]; then wifi_icon="󰤨"
                elif [ "$strength" -ge 50 ]; then wifi_icon="󰤥"
                elif [ "$strength" -ge 25 ]; then wifi_icon="󰤢"
                else wifi_icon="󰤟"
                fi
            else
                wifi_icon="󰤯"
            fi
        fi
    fi

    # 2. Status bluetooth (zabezpieczenie przed timeoutami)
    local bt_status="off"
    local bt_icon="󰂲"
    local bt_connected="Disconnected"

    if [ -d /sys/class/bluetooth ]; then
        if timeout 0.2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
            bt_status="on"
            bt_icon="󰂯"
            local dev=$(timeout 0.2 bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)
            if [ -n "$dev" ]; then
                bt_icon="󰂱"
                bt_connected="$dev"
            fi
        fi
    fi

    # 3. Status baterii (bezpośredni odczyt plików /sys bez procesów zewnętrznych!)
    local bat_percent="100"
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        bat_percent=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "100")
    fi
    local bat_icon="󰁹"
    if [ "$bat_percent" -ge 90 ]; then bat_icon="󰁹"
    elif [ "$bat_percent" -ge 70 ]; then bat_icon="󰂁"
    elif [ "$bat_percent" -ge 50 ]; then bat_icon="󰁿"
    elif [ "$bat_percent" -ge 30 ]; then bat_icon="󰁽"
    else bat_icon="󰁺"
    fi

    # Wypisanie 8 linii
    echo "$wifi_status"
    echo "$wifi_icon"
    echo "$wifi_ssid"
    echo "$bt_status"
    echo "$bt_icon"
    echo "$bt_connected"
    echo "$bat_percent"
    echo "$bat_icon"
}
```

---

## 4. Wyłączenie aktywnego skanowania Bluetooth w tle

Skrypt `qs_manager.sh` uruchamia nieustanne skanowanie bluetooth za pomocą polecenia `scan on` w potoku do `bluetoothctl`. Zamiast tego należy zmodyfikować panel sieciowy tak, aby wyszukiwanie urządzeń odbywało się **tylko i wyłącznie wtedy**, gdy panel sieciowy jest otwarty i widoczny dla użytkownika, a zamykanie panelu powinno natychmiast zatrzymywać procesy skanowania.
