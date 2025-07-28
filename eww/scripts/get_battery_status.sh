#!/bin/bash

# Script para obtener el estado de la batería, incluyendo un icono representativo.

# Busca la primera batería disponible
for battery_path in /sys/class/power_supply/BAT*; do
    if [ -d "$battery_path" ]; then
        BATTERY_DIR="$battery_path"
        break
    fi
done

# Si no se encuentra, sale con un mensaje de error
if [ -z "$BATTERY_DIR" ]; then
    echo "󰂃 Error"
    exit 1
fi

capacity=$(cat "$BATTERY_DIR/capacity")
status=$(cat "$BATTERY_DIR/status")

# Lógica para seleccionar el icono según el estado y la capacidad
if [ "$status" = "Charging" ]; then
    icon="" # Icono de rayo
else
    if [ "$capacity" -ge 95 ]; then
        icon="" # Batería llena
    elif [ "$capacity" -ge 70 ]; then
        icon="" # Batería a 3/4
    elif [ "$capacity" -ge 40 ]; then
        icon="" # Batería a 1/2
    elif [ "$capacity" -ge 15 ]; then
        icon="" # Batería a 1/4
    else
        icon="" # Batería vacía
    fi
fi

# Imprime solo el icono
echo "$icon"
