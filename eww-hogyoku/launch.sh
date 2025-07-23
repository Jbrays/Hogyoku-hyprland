#!/bin/bash

# Ruta al directorio de configuración de Eww
EWW_CONFIG_DIR="/home/jeff/Hogyoku/eww"

# Nombre de la ventana de la barra definida en eww.yuck
BAR_WINDOW="bar"

# Comprobar si la barra ya está abierta
if eww -c $EWW_CONFIG_DIR active-windows | grep -q "$BAR_WINDOW"; then
  # Si está abierta, la cerramos
  eww -c $EWW_CONFIG_DIR close $BAR_WINDOW
else
  # Si no está abierta, la abrimos
  eww -c $EWW_CONFIG_DIR open $BAR_WINDOW
fi
