#!/bin/bash

# Smart Escape Script v6 (Lógica de cierre corregida y portable)

# 1. Comprobar y cerrar Rofi
if pgrep -x rofi > /dev/null; then
    pkill -x rofi

# 2. Si swappy está activo, cerrar tanto swappy como su script padre.
elif pgrep -x swappy > /dev/null; then
    # Matar el script padre para evitar reinicios.
    pkill -9 -f "screenshot.sh"
    # Matar swappy directamente para asegurar el cierre.
    pkill -9 -x swappy

# 3. Si no, cerrar las ventanas de Eww con la configuración correcta.
else
    # Usar $HOME para portabilidad.
    /usr/bin/eww -c "$HOME/Hogyoku/eww" close calendar_win control_center_win brightness_osd mic_osd volume_osd
fi
