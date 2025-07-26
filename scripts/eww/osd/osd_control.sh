#!/bin/bash

EWW_CMD="eww -c $HOME/Hogyoku/eww"
VOL_PID_FILE="/tmp/eww-osd-volume.pid"
MIC_PID_FILE="/tmp/eww-osd-mic.pid"
BRIGHT_PID_FILE="/tmp/eww-osd-brightness.pid"

# --- FUNCIONES ---
show_volume_osd() {
    # Matar el temporizador de cierre anterior
    if [ -f "$VOL_PID_FILE" ]; then
        kill $(cat "$VOL_PID_FILE") 2>/dev/null
    fi

    # Obtener estado actual
    volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1)
    mute_status=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

    # Actualizar variables de Eww
    $EWW_CMD update volume_level=$volume
    $EWW_CMD update volume_muted=$([ "$mute_status" == "yes" ] && echo "true" || echo "false")

    # Abrir la ventana SOLO si no está ya abierta
    if ! $EWW_CMD active-windows | grep -q "volume_osd"; then
        $EWW_CMD open volume_osd
    fi

    # Iniciar un nuevo temporizador para cerrar la ventana
    (sleep 2 && $EWW_CMD close volume_osd) &
    echo $! > "$VOL_PID_FILE"
}

show_mic_osd() {
    if [ -f "$MIC_PID_FILE" ]; then kill $(cat "$MIC_PID_FILE") 2>/dev/null; fi
    mute_status=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
    $EWW_CMD update mic_muted=$([ "$mute_status" == "yes" ] && echo "true" || echo "false")

    if ! $EWW_CMD active-windows | grep -q "mic_osd"; then
        $EWW_CMD open mic_osd
    fi

    (sleep 2 && $EWW_CMD close mic_osd) &
    echo $! > "$MIC_PID_FILE"
}

show_brightness_osd() {
    if [ -f "$BRIGHT_PID_FILE" ]; then kill $(cat "$BRIGHT_PID_FILE") 2>/dev/null; fi

    if ! $EWW_CMD active-windows | grep -q "brightness_osd"; then
        $EWW_CMD open brightness_osd
    fi

    (sleep 2 && $EWW_CMD close brightness_osd) &
    echo $! > "$BRIGHT_PID_FILE"
}


# --- LÓGICA PRINCIPAL ---
case "$1" in
    volume)
        case "$2" in
            up) pactl set-sink-volume @DEFAULT_SINK@ +2%; show_volume_osd ;;
            down) pactl set-sink-volume @DEFAULT_SINK@ -2%; show_volume_osd ;;
            mute) pactl set-sink-mute @DEFAULT_SINK@ toggle; show_volume_osd ;;
        esac
        ;;
    mic)
        case "$2" in
            mute) pactl set-source-mute @DEFAULT_SOURCE@ toggle; show_mic_osd ;;
        esac
        ;;
    brightness)
        case "$2" in
            up) brightnessctl set +2%; show_brightness_osd ;;
            down) brightnessctl set 2%-; show_brightness_osd ;;
        esac
        ;;
esac
