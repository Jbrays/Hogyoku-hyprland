# Hogyoku - Análisis del Sistema de Theming Dinámico

Este documento describe el funcionamiento del sistema de generación de colores dinámicos extraído del proyecto `hyprland-material-you`. El objetivo es entender su mecanismo para poder replicarlo de forma independiente en Hogyoku.

## Resumen del Mecanismo

El sistema utiliza una estrategia de dos pasos para aplicar un esquema de colores basado en el fondo de pantalla a las aplicaciones GTK:

1.  **Generación de CSS Dinámico:** Utiliza SCSS (un preprocesador de CSS) para generar archivos CSS personalizados.
2.  **Aplicación del Tema:** Combina el uso de `gsettings` para establecer un tema base y la inyección de los archivos CSS generados para sobrescribir la apariencia de las aplicaciones GTK.

## Flujo de Trabajo Detallado

El archivo clave que orquesta todo el proceso es `hypryou/utils/colors.py`.

### 1. Generación de CSS a partir de Colores (vía SCSS)

El sistema no escribe CSS directamente, lo cual sería complejo. En su lugar, sigue estos pasos:

1.  **Extracción de Colores:** Una herramienta (probablemente `pywal` o una implementación interna similar) extrae una paleta de colores del fondo de pantalla actual.
2.  **Creación de Variables SCSS:** Los colores extraídos se escriben en un archivo de variables SCSS, que podría ser `_variables.scss`. Este archivo define los colores con nombres, como `$primary-color: #RRGGBB;`.
3.  **Uso de Plantillas SCSS:** El sistema utiliza plantillas base para los temas de GTK3 y GTK4, ubicadas en:
    *   `hypryou/assets/templates/gtk3.scss`
    *   `hypryou/assets/templates/gtk4.scss`
    Estas plantillas importan (`@use`) el archivo de variables de color.
4.  **Compilación a CSS:** Un compilador de SCSS procesa las plantillas y las variables, generando como salida los archivos CSS finales: `gtk-3.0.css` y `gtk-4.0.css`.

### 2. Aplicación del Tema a GTK

Esta es la parte crucial que afecta a las aplicaciones. Se realiza mediante una combinación de dos acciones en `hypryou/utils/colors.py`:

1.  **Establecimiento del Tema Base con `gsettings`:**
    El script ejecuta comandos `gsettings` para configurar el tema GTK base a nivel de sistema. Esto asegura que las aplicaciones tengan un punto de partida consistente. Los comandos son similares a estos:
    ```python
    gsettings = gio.Settings.new("org.gnome.desktop.interface")
    gsettings.set_string("gtk-theme", "adw-gtk3-dark")
    gsettings.set_string("color-scheme", "prefer-dark")
    ```

2.  **Inyección de CSS Personalizado:**
    Inmediatamente después, las funciones `update_gtk3()` y `update_gtk4()` copian los archivos CSS generados en el paso anterior a las ubicaciones de configuración de GTK del usuario:
    *   Desde `.../gtk-3.0.css` hacia `~/.config/gtk-3.0/gtk.css`
    *   Desde `.../gtk-4.0.css` hacia `~/.config/gtk-4.0/gtk.css`

## Conclusión

El "secreto" del sistema no es una característica mágica del tema `adw-gtk`, sino un proceso bien definido:

1.  **Establecer un tema GTK base** que sea robusto y compatible (como `adw-gtk3`).
2.  **Sobrescribir su apariencia** al colocar un archivo `gtk.css` generado dinámicamente en las carpetas de configuración de GTK.

Cualquier aplicación GTK que se inicie después de este proceso cargará automáticamente estos archivos `gtk.css`, aplicando así el esquema de colores extraído del fondo de pantalla. Esto proporciona una integración visual perfecta sin necesidad de modificar los temas GTK originales.

## Herramientas y Bibliotecas Utilizadas

La investigación ha confirmado que el sistema **no utiliza `pywal` ni `matugen`**. En su lugar, se basa en las siguientes herramientas para su funcionamiento:

1.  **`python-materialyoucolor`**: Esta es la biblioteca principal encargada de la lógica de color. Es una implementación en Python del algoritmo "Material You" de Google. Se utiliza para analizar los colores de una imagen y generar las paletas de colores completas (tanto para el modo claro como para el oscuro).

2.  **`Pillow` (PIL)**: Una biblioteca de Python para la manipulación de imágenes. Se usa para abrir el archivo del fondo de pantalla, leer sus datos de píxeles y prepararlos para que `materialyoucolor` los procese.

3.  **`sass` (Dart SASS)**: Es el compilador de SCSS. El sistema lo invoca como un subproceso para transformar los archivos de plantilla `.scss` en los archivos `.css` finales que GTK utilizará.

El proceso completo, desde la imagen hasta el tema final, se gestiona dentro del propio código Python y sus dependencias directas, sin llamar a herramientas externas de theming.

## Mecanismo de Cambio de Tema (Claro/Oscuro)

El sistema también maneja la capacidad de cambiar entre un modo claro y uno oscuro. La lógica se basa en un estado centralizado y la generación de paletas de colores separadas.

### Flujo del Cambio de Modo

1.  **Estado Centralizado:**
    *   Existe una variable global (en el código original, `dark_mode`) que actúa como la única fuente de verdad para saber si el modo oscuro está activo (`True`) o no (`False`).

2.  **Interfaz de Usuario (Interruptor):**
    *   Un interruptor (`ToggleButton`) en la interfaz de usuario está conectado a una función controladora.
    *   Cuando el usuario hace clic en el interruptor, se invoca a una función como `set_dark_mode(True/False)`, que actualiza el valor de la variable de estado central.

3.  **Lógica Condicional en el Backend:**
    *   **Paletas Separadas:** El sistema genera y mantiene dos esquemas de colores distintos: `light_scheme` y `dark_scheme`.
    *   **Selección de Tema:** La lógica principal del script de theming comprueba el estado de la variable `dark_mode`.
    *   **Aplicación con `gsettings`:** Basándose en si el modo es claro u oscuro, el script ajusta los comandos `gsettings` correspondientes:
        *   **Modo Oscuro:**
            ```
            gsettings.set_string("gtk-theme", "adw-gtk3-dark")
            gsettings.set_string("color-scheme", "prefer-dark")
            ```
        *   **Modo Claro:**
            ```
            gsettings.set_string("gtk-theme", "adw-gtk3")
            gsettings.set_string("color-scheme", "prefer-light")
            ```
    *   **Generación de CSS:** El script elige la paleta de colores correcta (`dark_scheme` o `light_scheme`) antes de compilar los archivos SCSS a CSS.

En esencia, el cambio de tema no es solo un cambio de CSS, sino una reconfiguración completa que implica tanto la paleta de colores para la generación de CSS como la configuración base de GTK a través de `gsettings`.
