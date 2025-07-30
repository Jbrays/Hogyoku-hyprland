[global]
    monitor = 0
    follow = mouse
    width = 300
    origin = bottom-right
    offset = (30,30)
    progress_bar = true
    progress_bar_height = 14
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    indicate_hidden = yes
    shrink = no
    separator_height = 6
    padding = 16
    horizontal_padding = 16
    frame_width = 5
    sort = no
    idle_threshold = 0
    font = "Hack Nerd Font 11"
    line_height = 0
    markup = full
    format = "<b>%a</b>\n%s\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 120
    word_wrap = yes
    ignore_newline = no
    stack_duplicates = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 50
    max_icon_size = 60
    icon_path = /usr/share/icons/gnome/128x128/status/:/usr/share/icons/gnome/128x128/devices/
    icon_theme = "Sevi, Adwaita"
    enable_recursive_icon_lookup = true
    sticky_history = yes
    history_length = 100
    dmenu = /usr/bin/dmenu -p dunst:
    browser = /usr/bin/firefox -new-tab
    always_run_script = false
    title = Dunst
    class = Dunst
    corner_radius = 16
    ignore_dbusclose = false
    force_xinerama = false
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

    # --- THEMED COLORS --- #
    frame_color = "$surfaceContainer"
    separator_color = "$surfaceContainer"

[experimental]
    per_monitor_dpi = false

[urgency_low]
    background = "$surface"
    foreground = "$onPrimaryContainer"
    highlight = "$primary"
    frame_color = "$surfaceContainerHigh"
    timeout = 8

[urgency_normal]
    script = $HOME/Hogyoku/scripts/dunst/sound-normal.sh
    background = "$surface"
    foreground = "$onPrimaryContainer"
    highlight = "$primary"
    timeout = 8

[urgency_critical]
    script = $HOME/Hogyoku/scripts/dunst/sound-critical.sh
    background = "$surface"
    foreground = "$onSurface"
    frame_color = "$error"
    highlight = "$onError"
    timeout = 0
    icon = battery-ac-adapter

[backlight]
    appname = "Backlight"
    highlight = "$primary"
    set_stack_tag = "backlight"

[music]
    appname = "Music"

[volume]
    summary = "Volume*"
    highlight = "$primary"
    set_stack_tag = "volume"

[battery]
    appname = "Power Warning"

[volume-muted]
    summary = "Volume muted"
    highlight = "$error"
