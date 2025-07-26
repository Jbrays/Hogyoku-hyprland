#!/bin/bash

# Script para obtener el estado de la conexión Wi-Fi usando iwd (iwctl).
# Versión final - Maneja códigos ANSI y parsing correcto

# Verificar si iwctl está disponible
if ! command -v iwctl &> /dev/null; then
    echo "error"
    exit 1
fi

# Función para limpiar códigos ANSI
strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# Obtener el nombre del dispositivo
# Usar línea 5 que contiene el dispositivo, extraer primer campo
DEVICE=$(iwctl device list 2>/dev/null | strip_ansi | sed -n '5p' | awk '{print $1}')

# Si no hay dispositivo, está apagado
if [[ -z "$DEVICE" ]]; then
    echo "off"
    exit 0
fi

# Verificar si el dispositivo está powered
# Buscar línea que contenga "Powered" y verificar si tiene "on"
POWER_LINE=$(iwctl device "$DEVICE" show 2>/dev/null | strip_ansi | grep -i "powered")
if [[ "$POWER_LINE" =~ on ]]; then
    POWER_ON=true
else
    POWER_ON=false
fi

# Si el dispositivo está apagado
if [[ "$POWER_ON" != true ]]; then
    echo "off"
    exit 0
fi

# Verificar el estado de la conexión
CONNECTION_STATE=$(iwctl station "$DEVICE" show 2>/dev/null | strip_ansi | grep -i "state" | awk '{print $2}')

case "$CONNECTION_STATE" in
    "connected")
        echo "connected"
        ;;
    "connecting")
        echo "connecting"
        ;;
    "disconnected"|"")
        echo "disconnected"
        ;;
    *)
        echo "disconnected"
        ;;
esac