#!/bin/bash

# Script para generar un estilo de degradado dinámico para eww

# Leer el color hexadecimal del tema, quitando el '#'
HEX_COLOR=$(jq -r '.surfaceContainer' "$HOME/Hogyoku/cache/colors.json" | sed 's/#//')

# Si el color no se encuentra, usar un negro por defecto para evitar errores
if [[ -z "$HEX_COLOR" ]]; then
    HEX_COLOR="000000"
fi

# Convertir los componentes hexadecimales (RR, GG, BB) a decimal
R=$(printf "%d" "0x${HEX_COLOR:0:2}")
G=$(printf "%d" "0x${HEX_COLOR:2:2}")
B=$(printf "%d" "0x${HEX_COLOR:4:2}")

# Imprimir la propiedad CSS completa que eww usará
echo "background-image: linear-gradient(to right, rgba($R, $G, $B, 1), rgba($R, $G, $B, 0.3));"
