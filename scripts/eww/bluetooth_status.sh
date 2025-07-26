#!/bin/bash

# Script para obtener el estado de la conexión Bluetooth.

# Comprobar si el servicio de bluetooth está activo.
if ! systemctl is-active --quiet bluetooth; then
    echo "off"
    exit 0
fi

# Comprobar si hay algún dispositivo conectado.
# `bluetoothctl info` solo devuelve información si hay un dispositivo conectado.
CONNECTED_DEVICE=$(bluetoothctl info | grep "Connected: yes")

if [[ -n "$CONNECTED_DEVICE" ]]; then
    echo "connected"
else
    # Si no hay dispositivo conectado, comprobamos si el controlador está encendido.
    POWERED_ON=$(bluetoothctl show | grep "Powered: yes")
    if [[ -n "$POWERED_ON" ]]; then
        echo "on" # Encendido pero no conectado
    else
        echo "off"
    fi
fi
