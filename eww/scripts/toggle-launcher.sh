#!/bin/bash

# Script para alternar la visibilidad del lanzador de aplicaciones de Eww

LAUNCHER_WINDOW="app_launcher"
EWW_BIN="eww -c /home/jeff/Hogyoku/eww"

# Obtener el estado actual de la variable 'launcher_reveal'
current_state=$($EWW_BIN get launcher_reveal)

if [ "$current_state" = "true" ]; then
  # Si está abierto, ciérralo
  $EWW_BIN update launcher_reveal=false
  $EWW_BIN close $LAUNCHER_WINDOW
else
  # Si está cerrado, ábrelo
  $EWW_BIN update launcher_reveal=true
  $EWW_BIN open $LAUNCHER_WINDOW
fi
