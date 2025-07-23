#!/bin/bash

# Ruta al archivo de estado y al script principal
STATE_FILE="$HOME/Hogyoku/cache/theme.state"
THEMER_SCRIPT="$HOME/Hogyoku/scripts/themer.py"
WALLPAPER_FILE="$HOME/Hogyoku/cache/current_wallpaper" # Necesitamos saber cuál es el fondo actual

# Determinar el modo actual (por defecto 'dark' si el archivo no existe)
CURRENT_MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")

# Cambiar al modo opuesto
if [ "$CURRENT_MODE" == "dark" ]; then
  NEW_MODE="light"
else
  NEW_MODE="dark"
fi

# Guardar el nuevo estado
echo "$NEW_MODE" > "$STATE_FILE"

# Obtener el fondo de pantalla actual (necesitamos que el selector lo guarde)
CURRENT_WALLPAPER=$(cat "$WALLPAPER_FILE" 2>/dev/null)

# Si no sabemos cuál es el fondo, no podemos hacer nada más
if [ -z "$CURRENT_WALLPAPER" ]; then
  echo "No se ha seleccionado un fondo de pantalla aún."
  exit 1
fi

# Volver a aplicar el tema con el nuevo modo
python3 "$THEMER_SCRIPT" --wallpaper "$CURRENT_WALLPAPER" --mode "$NEW_MODE"

# Recargar Eww
eww -c "$HOME/Hogyoku/eww-hogyoku" reload
eww -c "$HOME/Hogyoku/eww-hogy" reload

echo "Tema cambiado a $NEW_MODE"
