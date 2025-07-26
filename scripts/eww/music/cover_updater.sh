#!/bin/bash

# Script para escuchar cambios de canción y actualizar la carátula en segundo plano.

# El bucle asegura que si el comando falla o el reproductor se cierra,
# el script se reiniciará e intentará escuchar de nuevo.
while true; do
    # playerctl --follow esperará hasta que haya un cambio en los metadatos
    # (cambio de canción, pausa, etc.) y luego ejecutará el comando una vez.
    playerctl metadata --follow | while read -r _; do
        # Cuando hay un cambio, ejecutamos nuestro script de descarga de carátulas.
        bash "$HOME/Hogyoku/scripts/eww/music/music_cover.sh"
    done

    # Pequeña pausa antes de volver a intentar en caso de que el reproductor se cierre.
    sleep 1
done
