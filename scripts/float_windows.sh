#!/usr/bin/env bash

# Script para hacer la ventana activa flotante y darle tamaño específico si es kitty o nemo

# Hacer la ventana activa flotante
hyprctl dispatch togglefloating

# Obtener la clase de la ventana activa
winclass=$(hyprctl activewindow -j | jq -r '.class')

# Asignar tamaño según la clase
case "$winclass" in
    Alacritty)
        hyprctl dispatch resizeactive exact 900 600
        hyprctl dispatch centerwindow
        ;;
    org.gnome.Nautilus)
        hyprctl dispatch resizeactive exact 1100 800
        hyprctl dispatch centerwindow
        ;;
    *)
        # Para otras ventanas, tamaño general y centrado
        hyprctl dispatch resizeactive exact 1500 900
        hyprctl dispatch centerwindow
        ;;
esac