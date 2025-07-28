#!/bin/bash

# Script para obtener información de la batería y devolverla en formato JSON para Eww

get_battery_info() {
    # Busca la primera batería disponible en el sistema
    for battery in /sys/class/power_supply/BAT*; do
        if [ -d "$battery" ]; then
            CAPACITY_FILE="$battery/capacity"
            STATUS_FILE="$battery/status"
            
            if [ -f "$CAPACITY_FILE" ] && [ -f "$STATUS_FILE" ]; then
                capacity=$(cat "$CAPACITY_FILE")
                status=$(cat "$STATUS_FILE")
                
                # Devuelve la información en formato JSON
                echo "{\"percentage\": $capacity, \"status\": \"$status\"}"
                return
            fi
        fi
    done
    
    # Si no se encuentra ninguna batería
    echo "{\"percentage\": -1, \"status\": \"Not found\"}"
}

get_battery_info

