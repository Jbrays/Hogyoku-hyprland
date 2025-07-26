#!/bin/bash

# Script para lanzar una aplicación en segundo plano y luego cerrar el centro de control de eww.

# El primer argumento ($1) es el comando que queremos ejecutar.
if [[ -z "$1" ]]; then
    exit 1
fi

# Lanzar el comando en segundo plano.
$1 &

# Darle a eww un instante para "respirar" antes de enviarle otro comando.
sleep 0.1

# Cerrar la ventana del centro de control, especificando la ruta de la configuración.
/usr/bin/eww --config "$HOME/Hogyoku/eww" close control_center_win
