#!/bin/bash

# Script para escuchar cambios de canción y actualizar la carátula en segundo plano.
# Solo actualiza cuando cambia realmente la canción, no con cada evento de metadatos.

PLAYER="spotify,%any,firefox,chromium,brave,mpd"
LAST_TRACK=""

# Función para obtener identificador único de la canción actual
get_current_track() {
    local artist title
    artist=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)
    title=$(playerctl -p "$PLAYER" metadata title 2>/dev/null)
    echo "${artist}|||${title}"  # Separador único para evitar colisiones
}

# El bucle asegura que si el comando falla o el reproductor se cierre,
# el script se reiniciará e intentará escuchar de nuevo.
while true; do
    # Verificar si hay un reproductor activo
    if ! playerctl -p "$PLAYER" status &>/dev/null; then
        sleep 2
        continue
    fi
    
    # Obtener la canción actual
    CURRENT_TRACK=$(get_current_track)
    
    # Si la canción cambió, actualizar la portada
    if [[ "$CURRENT_TRACK" != "$LAST_TRACK" && -n "$CURRENT_TRACK" && "$CURRENT_TRACK" != "|||" ]]; then
        echo "Nueva canción detectada: $CURRENT_TRACK"
        bash "$HOME/Hogyoku/scripts/eww/music/music_cover.sh"
        LAST_TRACK="$CURRENT_TRACK"
    fi
    
    # Pausa antes de verificar de nuevo
    sleep 2
done
