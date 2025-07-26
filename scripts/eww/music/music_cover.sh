#!/bin/bash

# Script avanzado para obtener la carátula del álbum en alta resolución
# Usando un enfoque en cascada: iTunes -> MPRIS -> Fallback

TMP_DIR="$HOME/.cache/eww"
TMP_COVER_PATH="$TMP_DIR/cover.png"
FALLBACK_COVER_PATH="$HOME/Hogyoku/assets/music-fallback.png"

mkdir -p "$TMP_DIR"

# --- METADATOS ---
PLAYER="spotify,%any,firefox,chromium,brave,mpd"
ARTIST=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)
TITLE=$(playerctl -p "$PLAYER" metadata title 2>/dev/null)

if [[ -z "$ARTIST" || -z "$TITLE" ]]; then
    cp "$FALLBACK_COVER_PATH" "$TMP_COVER_PATH"
    exit 0
fi

# --- MÉTODO 1: ITUNES API (400x400) ---
SEARCH_TERM_ITUNES=$(echo "$ARTIST $TITLE" | sed 's/ /+/g; s/&/and/g')
ITUNES_URL=$(curl -s "https://itunes.apple.com/search?term=$SEARCH_TERM_ITUNES&entity=song&limit=1" | jq -r '.results[0].artworkUrl100')

if [[ -n "$ITUNES_URL" && "$ITUNES_URL" != "null" ]]; then
    # Solicitar un tamaño optimizado de 400x400
    OPTIMIZED_URL=$(echo "$ITUNES_URL" | sed 's/100x100/400x400/')
    curl -s -o "$TMP_COVER_PATH" "$OPTIMIZED_URL"
    if [[ -s "$TMP_COVER_PATH" ]]; then exit 0; fi
fi

# --- MÉTODO 2: MPRIS (BAJA RESOLUCIÓN) ---
MPRIS_URL=$(playerctl -p "$PLAYER" metadata mpris:artUrl 2>/dev/null)
if [[ -n "$MPRIS_URL" ]]; then
    if [[ "$MPRIS_URL" == "http"* ]]; then
        curl -s -o "$TMP_COVER_PATH" "$MPRIS_URL"
    elif [[ "$MPRIS_URL" == "file://"* ]]; then
        cp "${MPRIS_URL#file://}" "$TMP_COVER_PATH"
    fi
    if [[ -s "$TMP_COVER_PATH" ]]; then exit 0; fi
fi

# --- MÉTODO 3: FALLBACK FINAL ---
cp "$FALLBACK_COVER_PATH" "$TMP_COVER_PATH"
exit 0

