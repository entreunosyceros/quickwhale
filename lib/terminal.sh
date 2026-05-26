# Lanzar actividades en una terminal nueva (menú principal sigue visible)

qw_has_display() {
    [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
}

qw_build_runner_cmd() {
    # Construye el comando que ejecuta una función en modo hijo
    local func="$1"
    printf '%q run-activity %q' "$SCRIPT_PATH" "$func"
}

qw_open_terminal() {
    # $1=título, $2=comando completo a ejecutar en bash -lc
    local title="$1"
    local inner_cmd="$2"

    local wrapped
    wrapped="cd $(printf '%q' "$SCRIPT_DIR") && ${inner_cmd}; echo; read -r -p 'Pulsa Enter para cerrar esta ventana...' _"

    if command -v gnome-terminal &>/dev/null; then
        gnome-terminal --title="$title" -- bash -lc "$wrapped" &
        return 0
    fi
    if command -v konsole &>/dev/null; then
        konsole --new-tab -p tabtitle="$title" -e bash -lc "$wrapped" &
        return 0
    fi
    if command -v xfce4-terminal &>/dev/null; then
        xfce4-terminal --title="$title" -e bash -lc "$wrapped" &
        return 0
    fi
    if command -v xterm &>/dev/null; then
        xterm -T "$title" -e bash -lc "$wrapped" &
        return 0
    fi
    if command -v alacritty &>/dev/null; then
        alacritty --title "$title" -e bash -lc "$wrapped" &
        return 0
    fi
    if command -v kitty &>/dev/null; then
        kitty --title "$title" bash -lc "$wrapped" &
        return 0
    fi
    if command -v wt.exe &>/dev/null; then
        wt.exe -w 0 new-tab --title "$title" bash -lc "$wrapped" &
        return 0
    fi

    return 1
}

# Ejecuta una función: en terminal nueva si hay GUI, si no en la misma sesión
qw_launch() {
    local title="$1"
    local func="$2"

    if ! declare -F "$func" &>/dev/null; then
        msg_error "Actividad no encontrada: $func"
        return 1
    fi

    # Ya estamos en ventana hija
    if [[ "${QUICKWHALE_CHILD:-}" == "1" ]]; then
        "$func"
        return $?
    fi

    local runner
    runner="$(qw_build_runner_cmd "$func")"

    if qw_has_display && qw_open_terminal "$title" "$runner"; then
        msg_ok "Actividad abierta en nueva ventana: $title"
        return 0
    fi

    msg_aviso "No se detectó emulador gráfico; ejecutando en esta terminal."
    QUICKWHALE_CHILD=1 "$func"
    pausa
}

qw_run_activity_child() {
    local func="$1"
    export QUICKWHALE_CHILD=1
    if declare -F "$func" &>/dev/null; then
        "$func"
        echo
        read -r -p "Pulsa Enter para cerrar..." _ || true
        return 0
    fi
    msg_error "Función desconocida: $func"
    return 1
}
