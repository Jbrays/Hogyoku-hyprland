import os
import subprocess
import argparse
import json
import numpy as np
from PIL import Image

# --- Dependencias Requeridas ---
from materialyoucolor.quantize.celebi import QuantizeCelebi
from materialyoucolor.score.score import Score
from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity
from materialyoucolor.hct.hct import Hct

# --- Configuración ---
HOGYOKU_DIR = os.path.expanduser("~/Hogyoku")
CONFIG_DIR = os.path.expanduser("~/.config")
CACHE_DIR = os.path.join(HOGYOKU_DIR, "cache")
TEMPLATES_DIR = os.path.join(HOGYOKU_DIR, "templates")
DEFAULT_WALLPAPER = os.path.join(HOGYOKU_DIR, "default_wallpaper.jpg")

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
            pixels = np.array(img)[::4, ::4].reshape(-1, 3)
            quantized = QuantizeCelebi(pixels, 128)
            main_color = Score.score(quantized)[0]
            scheme = SchemeFidelity(Hct.from_int(main_color), is_dark=True, contrast_level=0.0)
            print("Paleta de colores base generada exitosamente.")
            return scheme
    except FileNotFoundError:
        print(f"Error: No se encontró el archivo de wallpaper en '{image_path}'")
        return None
    except Exception as e:
        print(f"Error al procesar la imagen: {e}")
        return None

def scheme_to_tonal_palette(scheme):
    """Extrae la paleta tonal completa de un esquema y la devuelve como un diccionario, manejando múltiples formatos de color."""
    tonal_palette_dict = {}
    tonal_groups = ["primary", "secondary", "tertiary", "neutral", "neutral_variant", "error"]
    tones = [0, 4, 10, 12, 17, 20, 22, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100]
    
    for group in tonal_groups:
        palette = getattr(scheme, f"{group}_palette", None)
        if palette:
            for tone in tones:
                color_val = palette.tone(tone)
                variable_name = f"{group}{tone}"
                
                # --- Lógica de Conversión de Color Robusta ---
                if isinstance(color_val, int):
                    # Formato Entero -> HEX
                    tonal_palette_dict[variable_name] = f"#{color_val:06x}"
                elif isinstance(color_val, (list, tuple)):
                    # Formato Lista/Tupla
                    if len(color_val) == 3:
                        # RGB -> HEX
                        tonal_palette_dict[variable_name] = '#{:02x}{:02x}{:02x}'.format(*color_val)
                    elif len(color_val) == 4:
                        # RGBA -> rgba()
                        r, g, b, a = color_val
                        if a == 255:
                            tonal_palette_dict[variable_name] = '#{:02x}{:02x}{:02x}'.format(r, g, b)
                        else:
                            alpha = round(a / 255, 3)
                            tonal_palette_dict[variable_name] = f'rgba({r},{g},{b},{alpha})'
                    else:
                        tonal_palette_dict[variable_name] = str(color_val)
                else:
                    tonal_palette_dict[variable_name] = str(color_val)
    return tonal_palette_dict

def apply_color_mapping(tonal_palette, mode):
    """Aplica el mapeo de colores claro/oscuro a una paleta tonal pre-generada."""
    if mode == 'dark':
        mapping = {
            "background": tonal_palette.get("neutral10"), "onBackground": tonal_palette.get("neutral90"),
            "surface": tonal_palette.get("neutral10"), "onSurface": tonal_palette.get("neutral90"),
            "onSurfaceVariant": tonal_palette.get("neutral_variant80"),
            "surfaceContainerLowest": tonal_palette.get("neutral4"), "surfaceContainerLow": tonal_palette.get("neutral10"),
            "surfaceContainer": tonal_palette.get("neutral12"), "surfaceContainerHigh": tonal_palette.get("neutral17"),
            "surfaceContainerHighest": tonal_palette.get("neutral22"),
            "primary": tonal_palette.get("primary80"), "onPrimary": tonal_palette.get("primary20"),
            "primaryContainer": tonal_palette.get("primary30"), "onPrimaryContainer": tonal_palette.get("primary90"),
            "secondaryContainer": tonal_palette.get("secondary30"), "onSecondaryContainer": tonal_palette.get("secondary90"),
            "outline": tonal_palette.get("neutral_variant60"),
            "error": tonal_palette.get("error80"), "onError": tonal_palette.get("error20"),
        }
    else: # Modo 'light'
        mapping = {
            "background": tonal_palette.get("neutral99"), "onBackground": tonal_palette.get("neutral10"),
            "surface": tonal_palette.get("neutral99"), "onSurface": tonal_palette.get("neutral10"),
            "onSurfaceVariant": tonal_palette.get("neutral_variant30"),
            "surfaceContainerLowest": tonal_palette.get("neutral100"), "surfaceContainerLow": tonal_palette.get("neutral95"),
            "surfaceContainer": tonal_palette.get("neutral90"), "surfaceContainerHigh": tonal_palette.get("neutral80"),
            "surfaceContainerHighest": tonal_palette.get("neutral70"),
            "primary": tonal_palette.get("primary40"), "onPrimary": tonal_palette.get("primary100"),
            "primaryContainer": tonal_palette.get("primary90"), "onPrimaryContainer": tonal_palette.get("primary10"),
            "secondaryContainer": tonal_palette.get("secondary90"), "onSecondaryContainer": tonal_palette.get("secondary10"),
            "outline": tonal_palette.get("neutral_variant50"),
            "error": tonal_palette.get("error40"), "onError": tonal_palette.get("error100"),
        }

    final_palette = {k: v for k, v in mapping.items() if v is not None}
    if "onBackground" in final_palette:
        final_palette["foreground"] = final_palette["onBackground"]
    return final_palette

def generate_scss_variables(palette):
    scss_vars_path = os.path.join(CACHE_DIR, "_variables.scss")
    with open(scss_vars_path, 'w') as f:
        for name, hex_color in palette.items():
            f.write(f"${name}: {hex_color};\n")

def generate_json_cache(palette):
    json_cache_path = os.path.join(CACHE_DIR, "colors.json")
    with open(json_cache_path, 'w') as f:
        json.dump(palette, f, indent=4)

def generate_hyprland_colors(palette):
    template_path = os.path.join(TEMPLATES_DIR, "hyprland.conf.tpl")
    output_path = os.path.join(CACHE_DIR, "hyprland_colors.conf")
    try:
        with open(template_path, 'r') as f:
            template_content = f.read()
        processed_content = template_content
        for name, hex_color in palette.items():
            clean_hex = hex_color.lstrip('#')
            hyprland_color = f"rgb({clean_hex})"
            processed_content = processed_content.replace(f"${name}", hyprland_color)
        with open(output_path, 'w') as f:
            f.write(processed_content)
    except Exception as e:
        print(f"Error al generar la configuración de Hyprland: {e}")

def generate_rofi_colors(palette):
    output_path = os.path.join(CACHE_DIR, "rofi-colors.rasi")
    try:
        lines = ["* {"]
        for name, hex_color in palette.items():
            lines.append(f"    {name}:        {hex_color};")
        lines.append("}")
        with open(output_path, 'w') as f:
            f.write("\n".join(lines))
    except Exception as e:
        print(f"Error al generar el tema de Rofi: {e}")

def compile_scss(template_name, output_name):
    template_path = os.path.join(TEMPLATES_DIR, template_name)
    output_path = os.path.join(CACHE_DIR, output_name)
    command = ["sass", "--load-path", CACHE_DIR, template_path, output_path]
    try:
        subprocess.run(command, check=True, capture_output=True, text=True)
        return True
    except Exception as e:
        print(f"Error al compilar {template_name}: {e.stderr if hasattr(e, 'stderr') else e}")
        return False

def apply_gtk_theme(mode):
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
    except Exception as e:
        print(f"Error al aplicar gsettings: {e}")

def copy_css_to_config():
    for v in ["3.0", "4.0"]:
        dest_path = os.path.join(CONFIG_DIR, f"gtk-{v}", "gtk.css")
        src_path = os.path.join(CACHE_DIR, f"gtk-{v}.css")
        if os.path.lexists(dest_path):
            os.remove(dest_path)
        subprocess.run(["cp", src_path, dest_path])

def generate_kitty_colors(palette):
    template_path = os.path.join(TEMPLATES_DIR, "kitty-colors.conf.tpl")
    output_path = os.path.join(CACHE_DIR, "kitty-colors.conf")
    color_map = {
        'color0': palette.get('onSurfaceVariant', '#d0d0d0'), 'color1': palette.get('error', '#ff5370'),
        'color2': palette.get('primary', '#c3e88d'), 'color3': palette.get('secondaryContainer', '#ffcb6b'),
        'color4': palette.get('primary', '#82aaff'), 'color5': palette.get('onPrimaryContainer', '#c792ea'),
        'color6': palette.get('outline', '#89ddff'), 'color7': palette.get('onSurface', '#d0d0d0'),
        'color8': palette.get('outline', '#89ddff'), 'color9': palette.get('onError', '#ff5370'),
        'color10': palette.get('primaryContainer', '#c3e88d'), 'color11': palette.get('onSecondaryContainer', '#ffcb6b'),
        'color12': palette.get('onPrimary', '#82aaff'), 'color13': palette.get('primary', '#c792ea'),
        'color14': palette.get('onSurfaceVariant', '#89ddff'), 'color15': palette.get('onBackground', '#ffffff'),
        'foreground': palette.get('foreground', '#e0e2e8'), 'background': palette.get('background', '#181c20'),
        'selection_foreground': palette.get('onPrimary', '#e0e2e8'), 'selection_background': palette.get('primary', '#9acbfa'),
        'url_color': palette.get('primary', '#9acbfa'),
    }
    try:
        with open(template_path, 'r') as f:
            template = f.read()
        for key, value in color_map.items():
            template = template.replace(f'{{{key}}}', value)
        import re
        template = re.sub(r'\{\w+\}', '', template)
        with open(output_path, 'w') as f:
            f.write(template)
    except Exception as e:
        print(f"Error al generar los colores de Kitty: {e}")

def generate_alacritty_colors_toml(palette):
    template_path = os.path.join(TEMPLATES_DIR, "alacritty-colors.toml.tpl")
    output_path = os.path.join(CACHE_DIR, "alacritty-colors.toml")
    color_map = {
        'color0': palette.get('onSurfaceVariant', '#d0d0d0'), 'color1': palette.get('error', '#ff5370'),
        'color2': palette.get('primary', '#c3e88d'), 'color3': palette.get('secondaryContainer', '#ffcb6b'),
        'color4': palette.get('primary', '#82aaff'), 'color5': palette.get('onPrimaryContainer', '#c792ea'),
        'color6': palette.get('outline', '#89ddff'), 'color7': palette.get('onSurface', '#d0d0d0'),
        'color8': palette.get('outline', '#89ddff'), 'color9': palette.get('onError', '#ff5370'),
        'color10': palette.get('primaryContainer', '#c3e88d'), 'color11': palette.get('onSecondaryContainer', '#ffcb6b'),
        'color12': palette.get('onPrimary', '#82aaff'), 'color13': palette.get('primary', '#c792ea'),
        'color14': palette.get('onSurfaceVariant', '#89ddff'), 'color15': palette.get('onBackground', '#ffffff'),
        'foreground': palette.get('foreground', '#e0e2e8'), 'background': palette.get('background', '#181c20'),
        'selection_foreground': palette.get('onPrimary', '#e0e2e8'), 'selection_background': palette.get('primary', '#9acbfa'),
        'cursor': palette.get('onBackground', '#ffffff'), 'cursor_text': palette.get('background', '#181c20'),
        'search_focused_bg': palette.get('primary', '#9acbfa'), 'search_focused_fg': palette.get('background', '#181c20'),
        'search_bg': palette.get('surfaceContainerHigh', '#313539'), 'search_fg': palette.get('onSurface', '#e0e2e8'),
        'hint_start_bg': palette.get('primaryContainer', '#0b4a72'), 'hint_start_fg': palette.get('onPrimaryContainer', '#cde5ff'),
        'hint_end_bg': palette.get('secondaryContainer', '#3a4857'), 'hint_end_fg': palette.get('onSecondaryContainer', '#d4e4f6'),
    }
    try:
        with open(template_path, 'r') as f:
            template = f.read()
        for key, value in color_map.items():
            template = template.replace(f'{{{key}}}', value)
        import re
        template = re.sub(r'\{\w+\}', '', template)
        with open(output_path, 'w') as f:
            f.write(template)
    except Exception as e:
        print(f"Error al generar los colores de Alacritty (TOML): {e}")

def generate_dunst_config(palette):
    template_path = os.path.join(TEMPLATES_DIR, "dunstrc.tpl")
    output_path = os.path.join(CACHE_DIR, "dunstrc")
    try:
        with open(template_path, 'r') as f:
            template_content = f.read()
        
        processed_content = template_content
        for name, hex_color in palette.items():
            processed_content = processed_content.replace(f'"${name}"', f'"{hex_color}"')

        with open(output_path, 'w') as f:
            f.write(processed_content)
    except Exception as e:
        print(f"Error al generar la configuración de Dunst: {e}")

def main():
    parser = argparse.ArgumentParser(description="Generador de temas dinámicos para Hogyoku.")
    parser.add_argument('--wallpaper', type=str, help="Ruta a la imagen del fondo de pantalla. Si se omite, se usa la paleta en caché.")
    parser.add_argument('--mode', type=str, choices=['light', 'dark'], default='dark', help="Modo del tema (claro u oscuro).")
    args = parser.parse_args()

    ensure_dirs()
    tonal_palette_cache_file = os.path.join(CACHE_DIR, "tonal_palette.json")

    if args.wallpaper:
        print("--- MODO ANÁLISIS: Generando nueva paleta desde el wallpaper ---")
        wallpaper_path = args.wallpaper
        if not os.path.exists(wallpaper_path):
            if not os.path.exists(DEFAULT_WALLPAPER):
                try:
                    Image.new('RGB', (1920, 1080), color = 'darkslateblue').save(DEFAULT_WALLPAPER)
                except Exception as e:
                    print(f"No se pudo crear el wallpaper por defecto: {e}")
                    return
            wallpaper_path = DEFAULT_WALLPAPER
        
        scheme = get_colors_from_wallpaper(wallpaper_path)
        if not scheme:
            print("No se pudo generar la paleta. Abortando.")
            return
        
        tonal_palette = scheme_to_tonal_palette(scheme)
        with open(tonal_palette_cache_file, 'w') as f:
            json.dump(tonal_palette, f)
        print(f"Paleta tonal guardada en caché: {tonal_palette_cache_file}")

    else:
        print("--- MODO RÁPIDO: Cargando paleta desde la caché ---")
        if not os.path.exists(tonal_palette_cache_file):
            print("Error: No existe una paleta en caché. Ejecute el script con --wallpaper primero.")
            return
        with open(tonal_palette_cache_file, 'r') as f:
            tonal_palette = json.load(f)

    print(f"Aplicando mapeo para el modo: {args.mode}")
    final_palette = apply_color_mapping(tonal_palette, args.mode)

    generate_scss_variables(final_palette)
    generate_json_cache(final_palette)
    generate_hyprland_colors(final_palette)
    generate_rofi_colors(final_palette)
    generate_kitty_colors(final_palette)
    generate_alacritty_colors_toml(final_palette)
    generate_dunst_config(final_palette)
    if not compile_scss("gtk3.scss", "gtk-3.0.css"): return
    if not compile_scss("gtk4.scss", "gtk-4.0.css"): return
    apply_gtk_theme(args.mode)
    copy_css_to_config()

    import shutil
    print("Copiando archivos de tema críticos a sus destinos persistentes...")
    rofi_src = os.path.join(CACHE_DIR, "rofi-colors.rasi")
    rofi_dst = os.path.join(HOGYOKU_DIR, "config/rofi/rofi-colors.rasi")
    shutil.copy(rofi_src, rofi_dst)
    kitty_src = os.path.join(CACHE_DIR, "kitty-colors.conf")
    kitty_dst = os.path.join(HOGYOKU_DIR, "config/kitty/kitty-colors.conf")
    shutil.copy(kitty_src, kitty_dst)
    alacritty_src = os.path.join(CACHE_DIR, "alacritty-colors.toml")
    alacritty_dst = os.path.join(HOGYOKU_DIR, "config/alacritty/alacritty-colors.toml")
    shutil.copy(alacritty_src, alacritty_dst)
    dunst_src = os.path.join(CACHE_DIR, "dunstrc")
    dunst_dst = os.path.join(HOGYOKU_DIR, "config/dunst/dunstrc")
    shutil.copy(dunst_src, dunst_dst)

    print("--- Proceso de Theming de Hogyoku Finalizado ---")

if __name__ == "__main__":
    main()