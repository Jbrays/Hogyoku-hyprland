#!/bin/bash

# Archivo de registro para este trabajador
LOG_FILE="/tmp/hogyoku_worker.log"
echo "--- TRABAJADOR INICIADO: $(date) ---" > "$LOG_FILE"
exec &> >(tee -a "$LOG_FILE")

# --- LÓGICA DE THEMING (movida desde switch_theme.sh) ---

STATE_FILE="$HOME/Hogyoku/cache/theme.state"
THEMER_SCRIPT="$HOME/Hogyoku/scripts/theming/themer.py"
WALLPAPER_FILE="$HOME/Hogyoku/cache/current_wallpaper"

CURRENT_MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")

if [ "$CURRENT_MODE" == "dark" ]; then
  NEW_MODE="light"
else
  NEW_MODE="dark"
fi

echo "$NEW_MODE" > "$STATE_FILE"

CURRENT_WALLPAPER=$(cat "$WALLPAPER_FILE" 2>/dev/null)
CURRENT_WALLPAPER="${CURRENT_WALLPAPER/#\~/$HOME}"

if [ -z "$CURRENT_WALLPAPER" ] || [ ! -f "$CURRENT_WALLPAPER" ]; then
  echo "Error Crítico: No se encontró el archivo de wallpaper en el trabajador. Abortando."
  exit 1
fi

echo "Trabajador: Ejecutando themer.py en modo RÁPIDO ('$NEW_MODE')..."
python3 "$THEMER_SCRIPT" --mode "$NEW_MODE"
echo "Trabajador: ¡themer.py ha terminado!"

# --- LÓGICA DE RECARGA ---

echo "Trabajador: Ejecutando eww reload..."
eww -c "$HOME/Hogyoku/eww" reload

echo "Trabajador: Enviando señal de recarga de colores a Kitty..."
kitty @ set-colors --all --configured ~/.config/kitty/kitty.conf

echo "Trabajador: Comando de recarga enviado."
echo "--- TRABAJADOR FINALIZADO ---"
