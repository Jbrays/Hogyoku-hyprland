#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path
from PIL import Image
import multiprocessing as mp

# --- Configuración ---
HOME = Path.home()
HOGYOKU_DIR = HOME / "Hogyoku"
WALLPAPER_DIR = HOME / "Imágenes/wallpapers"
CACHE_DIR = HOGYOKU_DIR / "cache"
THUMBNAIL_DIR = CACHE_DIR / "thumbnails"
STATE_FILE = CACHE_DIR / "theme.state"
THEMER_SCRIPT = HOGYOKU_DIR / "scripts" / "theming" / "themer.py"



def create_thumbnail(image_path: Path, thumbnail_path: Path):
    if thumbnail_path.exists(): return
    try:
        image = Image.open(image_path)
        width, height = image.size
        size = 256
        if width <= size and height <= size:
            image = image.resize((size, size), Image.Resampling.LANCZOS)
            image.save(thumbnail_path, "PNG")
            return
        # Redimensionar manteniendo proporción, lado corto = size
        if width > height:
            new_height = size
            new_width = int(width * size / height)
        else:
            new_width = size
            new_height = int(height * size / width)
        img = image.resize((new_width, new_height), Image.Resampling.LANCZOS)
        # Recortar cuadrado centrado
        left = (new_width - size) // 2
        top = (new_height - size) // 2
        right = left + size
        bottom = top + size
        img = img.crop((left, top, right, bottom))
        thumbnail_path.parent.mkdir(parents=True, exist_ok=True)
        img.save(thumbnail_path, "PNG")
    except Exception as e:
        print(f"Error creando miniatura para {image_path}: {e}", file=sys.stderr)

def generate_rofi_list() -> list[str]:
    THUMBNAIL_DIR.mkdir(parents=True, exist_ok=True)
    image_paths = list(WALLPAPER_DIR.glob("*.[jp][pn]g")) + list(WALLPAPER_DIR.glob("*.jpeg"))
    thumbnail_paths = [THUMBNAIL_DIR / f"{p.stem}.png" for p in image_paths]
    with mp.Pool(processes=mp.cpu_count()) as pool:
        pool.starmap(create_thumbnail, zip(image_paths, thumbnail_paths))
    return [f"{img.name}\0icon\x1f{thumb.resolve()}" for img, thumb in zip(image_paths, thumbnail_paths) if thumb.exists()]

def main():
    if not WALLPAPER_DIR.is_dir():
        msg = f"Error: El directorio de fondos no existe: {WALLPAPER_DIR}"
        subprocess.run(["zenity", "--error", f"--text={msg}"])
        sys.exit(1)

    rofi_entries = generate_rofi_list()
    if not rofi_entries:
        subprocess.run(["zenity", "--info", "--text=No se encontraron fondos de pantalla."])
        sys.exit(0)

    try:
        rofi_cmd = [
            "rofi", "-dmenu", "-i", "-p", "Wallpaper",
            "-theme", str(HOGYOKU_DIR / "config/rofi/selector.rasi")
        ]
        rofi_process = subprocess.run(rofi_cmd, input="\n".join(rofi_entries), capture_output=True, text=True, check=True)
        selected_wallpaper_name = rofi_process.stdout.strip()
    except subprocess.CalledProcessError:
        print("Selección cancelada.")
        sys.exit(0)

    if not selected_wallpaper_name:
        return

    wallpaper_path = WALLPAPER_DIR / selected_wallpaper_name

    # Guardar el wallpaper seleccionado para uso futuro (ej. cambio de tema)
    with open(CACHE_DIR / "current_wallpaper", "w") as f:
        f.write(str(wallpaper_path).replace(str(HOME), "~"))

    # --- Lógica de Theming ---
    try:
        current_mode = "dark"
        if STATE_FILE.exists():
            current_mode = STATE_FILE.read_text().strip()
        print(f"Cambiando fondo a: {wallpaper_path} y aplicando tema {current_mode}")
        subprocess.run(["swww", "img", str(wallpaper_path), "--transition-type", "any"], check=True)
        subprocess.run(["python3", str(THEMER_SCRIPT), "--wallpaper", str(wallpaper_path), "--mode", current_mode], check=True)
        print("¡Entorno actualizado con éxito!")
        # Recargar Eww-hogy
        subprocess.run(["eww", "-c", str(HOGYOKU_DIR / "eww"), "reload"])
    except Exception as e:
        print(f"Un error inesperado ocurrió: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
