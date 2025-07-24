#!/bin/bash

# Este script solo lanza el script trabajador en segundo plano y sale.
# Esto evita que el entorno de Eww mate el proceso de theming.

WORKER_SCRIPT="$HOME/Hogyoku/scripts/themer_worker.sh"

# nohup: asegura que el script siga corriendo aunque este script termine.
# &: ejecuta el comando en segundo plano.
# >/dev/null 2>&1: descarta toda la salida para no interferir con Eww.
nohup "$WORKER_SCRIPT" >/dev/null 2>&1 &
