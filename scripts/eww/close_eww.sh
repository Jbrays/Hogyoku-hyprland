#!/bin/bash
EWW_CMD="eww -c $HOME/Hogyoku/eww"

# Cierra todas las ventanas emergentes de Eww
$EWW_CMD close calendar_win control_center_win brightness_osd mic_osd volume_osd

# Cierra rofi (lanzador y selectores basados en rofi)
pkill rofi

# Cierra swappy (editor de capturas de pantalla)
pkill swappy
