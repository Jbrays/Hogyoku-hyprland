#!/bin/bash

# --- Configuración ---
BATTERY_PATH="/sys/class/power_supply/BAT1"
LOCK_DIR="/tmp/battery_notifications"
mkdir -p "$LOCK_DIR"

# --- Niveles de Notificación ---
CRITICAL_LEVEL=9
LOW_LEVEL=19
FULL_LEVEL=100

# --- Función para enviar notificaciones ---
send_notification() {
    local urgency="$1"
    local summary="$2"
    local body="$3"
    notify-send -u "$urgency" -a "Power Warning" "$summary" "$body"
}

while true; do
    if [ ! -d "$BATTERY_PATH" ]; then
        # Si la ruta de la batería no existe, salir.
        exit 0
    fi

    capacity=$(cat "$BATTERY_PATH/capacity")
    status=$(cat "$BATTERY_PATH/status")

    if [ "$status" == "Discharging" ]; then
        # --- Lógica de Batería Baja ---
        
        # Nivel Crítico (9%)
        if [ "$capacity" -le $CRITICAL_LEVEL ] && [ ! -f "$LOCK_DIR/critical_notified" ]; then
            send_notification "critical" "Batería Crítica" "Nivel de batería al $capacity%. Conecta el cargador inmediatamente."
            touch "$LOCK_DIR/critical_notified"
        
        # Nivel Bajo (19%)
        elif [ "$capacity" -le $LOW_LEVEL ] && [ ! -f "$LOCK_DIR/low_notified" ]; then
            send_notification "normal" "Batería Baja" "Nivel de batería al $capacity%. Considera conectar el cargador."
            touch "$LOCK_DIR/low_notified"
        fi

        # Limpiar el lock de batería llena si se empieza a descargar
        if [ -f "$LOCK_DIR/full_notified" ]; then
            rm "$LOCK_DIR/full_notified"
        fi

    elif [ "$status" == "Charging" ] || [ "$status" == "Full" ]; then
        # --- Lógica de Carga y Batería Llena ---

        # Batería Llena (100%)
        if [ "$capacity" -ge $FULL_LEVEL ] && [ ! -f "$LOCK_DIR/full_notified" ]; then
            send_notification "normal" "Batería Cargada" "La batería ha alcanzado el 100%."
            touch "$LOCK_DIR/full_notified"
        fi

        # Limpiar los locks de batería baja cuando se conecta el cargador
        if [ "$capacity" -gt $LOW_LEVEL ]; then
            rm -f "$LOCK_DIR/low_notified"
            rm -f "$LOCK_DIR/critical_notified"
        fi
    fi

    # Esperar 5 minutos antes de la siguiente comprobación
    sleep 300
done
