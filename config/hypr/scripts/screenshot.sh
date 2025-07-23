#!/bin/bash

DIR="$HOME/Imágenes/screenshots/"
NAME="screenshot_$(date +%d%m%Y_%H%M%S).png"
TMP_FILE="/tmp/$NAME" # Para usar en swappy

# --- Tiempos de Espera Configurables ---
BRIEF_PAUSE_FOR_QUICK_CHECK=0.00 # Muy breve, para el primer intento (ej. 20ms)
MAX_ATTEMPTS=40                  # Número máximo de intentos
WAIT_BETWEEN_ATTEMPTS=0.05        # Tiempo entre intentos de verificación
MAX_SWAPPY_ATTEMPTS=5           # Número máximo de intentos para swappy

# Función para limpiar archivos temporales
cleanup() {
    # Eliminar el archivo temporal de la captura
    [ -f "$TMP_FILE" ] && rm -f "$TMP_FILE"
    # Eliminar el archivo temporal de errores de swappy
    [ -f "/tmp/swappy_error" ] && rm -f "/tmp/swappy_error"
    echo "Limpieza de archivos temporales completada."
}

# Asegurarse de que cleanup se ejecute al salir del script
trap cleanup EXIT

# Asegurarse de que el directorio de destino exista
mkdir -p "$DIR"

# --- Lógica original para hyprshot ---
if [[ "$1" == "--window" ]]; then
    echo "Modo: Ventana. Ejecutando hyprshot..."
    hyprshot -m window -o "/tmp" -f "$NAME" -s
elif [[ "$1" == "--active" ]]; then
    echo "Modo: Activa (original con -m active -m output). Ejecutando hyprshot..."
    hyprshot -m active -m output -o "/tmp" -f "$NAME" -s
else
    echo "Modo: Región (por defecto). Ejecutando hyprshot..."
    hyprshot -m region -o "/tmp" -f "$NAME" -s --
fi
# --- Fin de la lógica de hyprshot ---

echo "Hyprshot ha terminado de ejecutarse."

# --- Lógica de Espera Condicional ---
FILE_READY_FOR_SWAPPY=false

echo "Esperando ${BRIEF_PAUSE_FOR_QUICK_CHECK}s (para un chequeo rápido)..."
sleep "$BRIEF_PAUSE_FOR_QUICK_CHECK"

if [ -f "$TMP_FILE" ] && [ -s "$TMP_FILE" ]; then
    # Verificar si el tipo MIME es image/png como un chequeo ligero de validez
    MIME_TYPE=$(file -b --mime-type "$TMP_FILE")
    if [[ "$MIME_TYPE" == "image/png" ]]; then
        echo "Chequeo rápido: Archivo '$TMP_FILE' parece listo y es PNG (Tipo: $MIME_TYPE)."
        FILE_READY_FOR_SWAPPY=true
    else
        echo "Chequeo rápido: Archivo '$TMP_FILE' encontrado, pero no parece ser un PNG válido (Tipo: $MIME_TYPE). Se esperará más."
    fi
else
    echo "Chequeo rápido: Archivo '$TMP_FILE' no encontrado o vacío. Se esperará."
fi

# Función para verificar si el PNG es válido usando identify (de ImageMagick)
verify_png() {
    local file="$1"
    if command -v identify >/dev/null 2>&1; then
        if identify "$file" >/dev/null 2>&1; then
            return 0  # PNG válido
        fi
    else
        echo "Advertencia: 'identify' no está instalado. La verificación será menos precisa."
        # Si identify no está disponible, hacemos una verificación básica
        if [ -f "$file" ] && [ -s "$file" ]; then
            MIME_TYPE=$(file -b --mime-type "$file")
            if [[ "$MIME_TYPE" == "image/png" ]]; then
                return 0
            fi
        fi
    fi
    return 1  # PNG inválido o incompleto
}

if [ "$FILE_READY_FOR_SWAPPY" = false ]; then
    echo "Archivo no listo en el chequeo rápido. Iniciando verificación periódica..."
    attempt=1
    while [ "$FILE_READY_FOR_SWAPPY" = false ] && [ $attempt -le $MAX_ATTEMPTS ]; do
        echo "Intento $attempt de $MAX_ATTEMPTS..."
        sleep "$WAIT_BETWEEN_ATTEMPTS"
        
        if verify_png "$TMP_FILE"; then
            echo "Archivo '$TMP_FILE' está listo y es un PNG válido."
            FILE_READY_FOR_SWAPPY=true
        else
            echo "Archivo no válido o incompleto. Reintentando..."
        fi
        
        ((attempt++))
    done

    if [ "$FILE_READY_FOR_SWAPPY" = false ]; then
        echo "¡Advertencia! No se pudo verificar el archivo después de $MAX_ATTEMPTS intentos."
        echo "Continuando de todos modos..."
    fi
fi
# --- Fin de la lógica de Espera Condicional ---

# Intentar abrir con swappy con reintentos
echo "Intentando abrir '$TMP_FILE' con Swappy y guardar en '$DIR$NAME'..."
swappy_attempt=1
swappy_success=false

while [ $swappy_attempt -le $MAX_SWAPPY_ATTEMPTS ] && [ "$swappy_success" = false ]; do
    if [ $swappy_attempt -gt 1 ]; then
        echo "Reintentando con swappy (intento $swappy_attempt de $MAX_SWAPPY_ATTEMPTS)..."
        sleep "$WAIT_BETWEEN_ATTEMPTS"
    fi
    
    if swappy -f "$TMP_FILE" -o "$DIR$NAME" 2>/tmp/swappy_error; then
        swappy_success=true
        echo "¡Swappy se ejecutó correctamente!"
    else
        error_msg=$(cat /tmp/swappy_error)
        echo "Swappy falló: $error_msg"
    fi
    
    ((swappy_attempt++))
done

if [ "$swappy_success" = false ]; then
    echo "Error: No se pudo procesar la imagen con swappy después de $MAX_SWAPPY_ATTEMPTS intentos."
    exit 1
fi

echo "Script finalizado exitosamente."

