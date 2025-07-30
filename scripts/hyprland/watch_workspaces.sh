#!/bin/bash

# --- Eww Configuration ---
EWW_CMD="eww -c $HOME/Hogyoku/eww"

# --- Main Logic ---
# Limpiar la variable de urgencia al iniciar
$EWW_CMD update urgent_ws_name=""

# Conectar al socket de Hyprland
SOCKET_PATH="/run/user/$(id -u)/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
if [ ! -S "$SOCKET_PATH" ]; then exit 1; fi

# Escuchar eventos. Usamos stdbuf para minimizar cualquier posible retraso del lado del script.
stdbuf -o0 socat -U - "UNIX-CONNECT:$SOCKET_PATH" | stdbuf -o0 sed -u 's/>>*/ /' | while read -r event_data; do
    event_type=$(echo "$event_data" | cut -d' ' -f1)
    event_payload=$(echo "$event_data" | cut -d' ' -f2-)

    case $event_type in
        urgent)
            # Este evento tiene un retraso de ~2s incorporado en Hyprland
            window_address="0x$event_payload"
            
            # Preguntar a Hyprland por el workspace de la ventana urgente
            ws_name=$(hyprctl clients -j | jq -r --arg addr "$window_address" '.[] | select(.address == $addr) | .workspace.name')
            active_ws_name=$(hyprctl activeworkspace -j | jq -r '.name')

            if [ -n "$ws_name" ] && [ "$ws_name" != "$active_ws_name" ]; then
                $EWW_CMD update urgent_ws_name="$ws_name"
            fi
            ;;

        workspace|workspacev2)
            # Limpiar la urgencia al cambiar al workspace
            new_active_ws_name=$(echo "$event_payload" | cut -d',' -f1)
            current_urgent_ws=$($EWW_CMD get urgent_ws_name)
            
            if [ -n "$current_urgent_ws" ] && [ "$current_urgent_ws" != "null" ] && [ "$current_urgent_ws" == "$new_active_ws_name" ]; then
                $EWW_CMD update urgent_ws_name=""
            fi
            ;;
    esac
done
