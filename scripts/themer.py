import os
import subprocess
import argparse
import json
import numpy as np
from PIL import Image

# --- Dependencias Requeridas ---
# Pillow: para manipular imágenes (pip install Pillow)
# python-materialyoucolor-git: para el algoritmo de Material You (desde AUR)
from materialyoucolor.quantize.celebi import QuantizeCelebi
from materialyoucolor.score.score import Score
from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot
from materialyoucolor.hct.hct import Hct

# --- Configuración ---
HOGYOKU_DIR = os.path.expanduser("~/Hogyoku")
CONFIG_DIR = os.path.expanduser("~/.config")
CACHE_DIR = os.path.join(HOGYOKU_DIR, "cache")
TEMPLATES_DIR = os.path.join(HOGYOKU_DIR, "templates")
DEFAULT_WALLPAPER = os.path.join(HOGYOKU_DIR, "default_wallpaper.jpg") # Un wallpaper por defecto

# Nombres de colores de Material You que las plantillas SCSS esperan.
MATERIAL_COLORS = [
    "background", "onBackground", "surface", "onSurface", "onSurfaceVariant",
    "surfaceContainerLowest", "surfaceContainer", "surfaceContainerHighest",
    "primary", "onPrimary", "primaryContainer", "onPrimaryContainer",
    "secondaryContainer", "onSecondaryContainer", "outline", "error", "onError"
]

def ensure_dirs():
    """Asegura que los directorios necesarios existan."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    os.makedirs(os.path.join(CONFIG_DIR, "gtk-3.0"), exist_ok=True)
    os.makedirs(os.path.join(CONFIG_DIR, "gtk-4.0"), exist_ok=True)

def get_colors_from_wallpaper(image_path):
    """Extrae la paleta de colores de una imagen usando el algoritmo de Material You."""
    print(f"Procesando wallpaper: {image_path}")
    try:
        with Image.open(image_path).convert('RGB') as img:
            pixels = np.array(img)[::2, ::2].reshape(-1, 3)
            quantized = QuantizeCelebi(pixels, 128)
            main_color = Score.score(quantized)[0]
            
            # Generamos UN ÚNICO esquema base. El modo claro/oscuro se decide por el mapeo de tonos.
            scheme = SchemeTonalSpot(Hct.from_int(main_color), is_dark=True, contrast_level=0.0)
            
            print("Paleta de colores base generada exitosamente.")
            return scheme
    except FileNotFoundError:
        print(f"Error: No se encontró el archivo de wallpaper en '{image_path}'")
        return None
    except Exception as e:
        print(f"Error al procesar la imagen: {e}")
        return None

def scheme_to_dict(scheme, mode):
    """Convierte un objeto Scheme de Material You a un diccionario de colores HEX."""
    palette = {}
    tonal_palettes = [
        "primary", "secondary", "tertiary", "neutral", "neutral_variant", "error"
    ]
    # Generamos una amplia gama de tonos para tener flexibilidad
    required_tones = [0, 4, 10, 12, 17, 20, 22, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100]
    for p_name in tonal_palettes:
        tonal_palette = getattr(scheme, f"{p_name}_palette", None)
        if tonal_palette:
            for tone in required_tones:
                color_int = tonal_palette.tone(tone)
                variable_name = f"{p_name}{tone}"
                # Manejo robusto de formatos
                if isinstance(color_int, int):
                    palette[variable_name] = f"#{color_int:06x}"
                elif isinstance(color_int, (list, tuple)):
                    if len(color_int) == 3:
                        palette[variable_name] = '#{:02x}{:02x}{:02x}'.format(*color_int)
                    elif len(color_int) == 4:
                        r, g, b, a = color_int
                        if a == 255:
                            palette[variable_name] = '#{:02x}{:02x}{:02x}'.format(r, g, b)
                        else:
                            alpha = round(a / 255, 3)
                            palette[variable_name] = f'rgba({r},{g},{b},{alpha})'
                    else:
                        palette[variable_name] = str(color_int)
                else:
                    palette[variable_name] = str(color_int)

    # El mapeo ahora depende del modo (claro u oscuro) para seleccionar los tonos correctos
    if mode == 'dark':
        mapping = {
            "background": palette.get("neutral10"),
            "onBackground": palette.get("neutral90"),
            "surface": palette.get("neutral10"),
            "onSurface": palette.get("neutral90"),
            "onSurfaceVariant": palette.get("neutral_variant80"),
            "surfaceContainerLowest": palette.get("neutral4"),
            "surfaceContainerLow": palette.get("neutral10"),
            "surfaceContainer": palette.get("neutral12"),
            "surfaceContainerHigh": palette.get("neutral17"),
            "surfaceContainerHighest": palette.get("neutral22"),
            "primary": palette.get("primary80"),
            "onPrimary": palette.get("primary20"),
            "primaryContainer": palette.get("primary30"),
            "onPrimaryContainer": palette.get("primary90"),
            "secondaryContainer": palette.get("secondary30"),
            "onSecondaryContainer": palette.get("secondary90"),
            "outline": palette.get("neutral_variant60"),
            "error": palette.get("error80"),
            "onError": palette.get("error20"),
        }
    else: # Modo 'light'
        mapping = {
            "background": palette.get("neutral99"),
            "onBackground": palette.get("neutral10"),
            "surface": palette.get("neutral99"),
            "onSurface": palette.get("neutral10"),
            "onSurfaceVariant": palette.get("neutral_variant30"),
            "surfaceContainerLowest": palette.get("neutral100"),
            "surfaceContainerLow": palette.get("neutral95"),
            "surfaceContainer": palette.get("neutral90"),
            "surfaceContainerHigh": palette.get("neutral80"),
            "surfaceContainerHighest": palette.get("neutral70"),
            "primary": palette.get("primary40"),
            "onPrimary": palette.get("primary100"),
            "primaryContainer": palette.get("primary90"),
            "onPrimaryContainer": palette.get("primary10"),
            "secondaryContainer": palette.get("secondary90"),
            "onSecondaryContainer": palette.get("secondary10"),
            "outline": palette.get("neutral_variant50"),
            "error": palette.get("error40"),
            "onError": palette.get("error100"),
        }

    final_palette = {k: v for k, v in mapping.items() if v is not None}
    if "onBackground" in final_palette:
        final_palette["foreground"] = final_palette["onBackground"]
    return final_palette

def generate_scss_variables(palette):
    """Genera el archivo _variables.scss a partir de una paleta de colores."""
    scss_vars_path = os.path.join(CACHE_DIR, "_variables.scss")
    print(f"Generando variables SCSS en: {scss_vars_path}")
    with open(scss_vars_path, 'w') as f:
        for name, hex_color in palette.items():
            f.write(f"${name}: {hex_color};\n")
    print("Variables SCSS generadas.")

def generate_json_cache(palette):
    """Guarda la paleta de colores en un archivo JSON para que Eww la consuma."""
    json_cache_path = os.path.join(CACHE_DIR, "colors.json")
    print(f"Generando caché JSON en: {json_cache_path}")
    with open(json_cache_path, 'w') as f:
        json.dump(palette, f, indent=4)
    print("Caché JSON generada.")

def generate_hyprland_colors(palette):
    """Genera el archivo de colores de Hyprland a partir de una plantilla."""
    template_path = os.path.join(TEMPLATES_DIR, "hyprland.conf.tpl")
    output_path = os.path.join(CACHE_DIR, "hyprland_colors.conf")
    
    print(f"Generando configuración de Hyprland en: {output_path}")
    
    try:
        with open(template_path, 'r') as f:
            template_content = f.read()
        
        # Reemplazar los marcadores de posición con los colores de la paleta
        # Convertimos los colores HEX a un formato que Hyprland entienda (sin #)
        processed_content = template_content
        for name, hex_color in palette.items():
            hypr_color = hex_color.lstrip('#')
            processed_content = processed_content.replace(f"${name}", hypr_color)
            
        with open(output_path, 'w') as f:
            f.write(processed_content)
            
        print("Configuración de Hyprland generada.")
        
    except FileNotFoundError:
        print(f"Error: No se encontró la plantilla en '{template_path}'")
    except Exception as e:
        print(f"Error al generar la configuración de Hyprland: {e}")

def compile_scss(template_name, output_name):
    """Compila una plantilla SCSS a un archivo CSS."""
    template_path = os.path.join(TEMPLATES_DIR, template_name)
    output_path = os.path.join(CACHE_DIR, output_name)
    command = ["sass", "--load-path", CACHE_DIR, template_path, output_path]
    
    print(f"Compilando {template_name} -> {output_name}...")
    try:
        subprocess.run(command, check=True, capture_output=True, text=True)
        print(f"Compilación de {template_name} exitosa.")
        return True
    except FileNotFoundError:
        print("Error: El comando 'sass' no fue encontrado.")
        return False
    except subprocess.CalledProcessError as e:
        print(f"Error al compilar {template_name}:\n{e.stderr}")
        return False

def apply_gtk_theme(mode):
    """Aplica el tema GTK base usando gsettings según el modo."""
    print(f"Aplicando tema GTK base para el modo '{mode}'...")
    try:
        import gi
        gi.require_version('Gio', '2.0')
        from gi.repository import Gio
        gsettings = Gio.Settings.new("org.gnome.desktop.interface")
        if mode == 'dark':
            gsettings.set_string("gtk-theme", "adw-gtk3-dark")
            gsettings.set_string("color-scheme", "prefer-dark")
        else:
            gsettings.set_string("gtk-theme", "adw-gtk3")
            gsettings.set_string("color-scheme", "prefer-light")
        print("Tema GTK base aplicado correctamente.")
    except Exception as e:
        print(f"Error al aplicar gsettings: {e}")

def copy_css_to_config():
    """Elimina los archivos CSS existentes y copia los nuevos a las carpetas de GTK."""
    for v in ["3.0", "4.0"]:
        dest_path = os.path.join(CONFIG_DIR, f"gtk-{v}", "gtk.css")
        src_path = os.path.join(CACHE_DIR, f"gtk-{v}.css")
        
        if os.path.lexists(dest_path):
            os.remove(dest_path)
        
        print(f"Copiando {src_path} -> {dest_path}")
        subprocess.run(["cp", src_path, dest_path])
    print("Archivos CSS copiados a las carpetas de configuración.")

def main():
    parser = argparse.ArgumentParser(description="Generador de temas dinámicos para Hogyoku.")
    parser.add_argument('--wallpaper', type=str, help="Ruta a la imagen del fondo de pantalla.")
    parser.add_argument('--mode', type=str, choices=['light', 'dark'], default='dark', help="Modo del tema (claro u oscuro).")
    args = parser.parse_args()

    wallpaper_path = args.wallpaper
    if not wallpaper_path:
        # Si no se proporciona wallpaper, intenta usar uno por defecto.
        # Primero, crea un wallpaper de ejemplo si no existe.
        if not os.path.exists(DEFAULT_WALLPAPER):
            try:
                Image.new('RGB', (1920, 1080), color = 'darkslateblue').save(DEFAULT_WALLPAPER)
                print(f"Creado wallpaper por defecto en: {DEFAULT_WALLPAPER}")
            except Exception as e:
                print(f"No se pudo crear el wallpaper por defecto: {e}")
                return
        wallpaper_path = DEFAULT_WALLPAPER

    print(f"--- Iniciando Proceso de Theming de Hogyoku (Modo: {args.mode}) ---")
    ensure_dirs()
    scheme = get_colors_from_wallpaper(wallpaper_path)
    if not scheme:
        print("No se pudo generar la paleta. Abortando.")
        return

    # Generar la paleta final usando el mapeo de tonos correcto para el modo elegido
    final_palette = scheme_to_dict(scheme, args.mode)

    # (Opcional) Dejaré el DEBUG para que puedas verificar la paleta final
    print("--- Paleta Final Generada (DEBUG) ---")
    print(final_palette)
    print("--- Fin del DEBUG ---")

    generate_scss_variables(final_palette)
    generate_json_cache(final_palette)
    generate_hyprland_colors(final_palette)
    if not compile_scss("gtk3.scss", "gtk-3.0.css"): return
    if not compile_scss("gtk4.scss", "gtk-4.0.css"): return
    apply_gtk_theme(args.mode)
    copy_css_to_config()
    print("--- Proceso de Theming de Hogyoku Finalizado ---")

if __name__ == "__main__":
    main()
