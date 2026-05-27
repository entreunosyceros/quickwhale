# Lanzar actividades en una terminal nueva (menú principal sigue visible)

qw_has_display() {
    [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
}

qw_tiene_dbus() {
    [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] \
        || existe_comando dbus-launch \
        || [[ -x /usr/bin/dbus-launch ]]
}

qw_gnome_terminal_disponible() {
    existe_comando gnome-terminal || return 1
    qw_tiene_dbus
}

qw_env_terminal() {
    env \
        DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}" \
        DISPLAY="${DISPLAY:-}" \
        WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
        XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" \
        XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-}" \
        "$@"
}

# Lista de emuladores conocidos (sin xterm: aspecto distinto al del escritorio)
qw_lista_emuladores_conocidos() {
    printf '%s\n' \
        gnome-terminal \
        konsole \
        xfce4-terminal \
        mate-terminal \
        lxterminal \
        tilix \
        terminator \
        alacritty \
        kitty \
        xterm
}

qw_hay_lanzador_terminal() {
    [[ -n "${QUICKWHALE_TERMINAL:-}" && -x "$(command -v "$QUICKWHALE_TERMINAL" 2>/dev/null)" ]] \
        && return 0
    existe_comando xdg-terminal-exec && return 0
    existe_comando x-terminal-emulator && return 0
    [[ -n "${TERMINAL:-}" && -x "$(command -v "$TERMINAL" 2>/dev/null)" ]] && return 0
    local e
    while IFS= read -r e; do
        [[ -z "$e" ]] && continue
        if qw_emulador_usable "$e"; then
            return 0
        fi
    done < <(qw_lista_emuladores_conocidos)
    existe_comando wt.exe
}

qw_emulador_usable() {
    case "$1" in
        gnome-terminal) qw_gnome_terminal_disponible ;;
        *) existe_comando "$1" ;;
    esac
}

qw_instalar_emulador_terminal() {
    if ! es_ubuntu && ! existe_comando apt-get; then
        msg_aviso "Instala manualmente un emulador gráfico (gnome-terminal, xfce4-terminal...)."
        return 1
    fi

    local pkgs=() p
    if ! qw_hay_lanzador_terminal; then
        pkgs+=(gnome-terminal xdg-utils)
    fi
    if existe_comando gnome-terminal && ! qw_tiene_dbus; then
        pkgs+=(dbus-x11)
    fi

    if [[ ${#pkgs[@]} -eq 0 ]]; then
        return 0
    fi

    # Eliminar duplicados
    local uniq=() seen
    for p in "${pkgs[@]}"; do
        seen=0
        for u in "${uniq[@]:-}"; do
            [[ "$u" == "$p" ]] && { seen=1; break; }
        done
        [[ "$seen" -eq 0 ]] && uniq+=("$p")
    done

    msg_info "Paquetes necesarios para ventanas nuevas: ${uniq[*]}"

    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        apt-get update -qq
        apt-get install -y -qq "${uniq[@]}"
        return $?
    fi

    if sudo -n true 2>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${uniq[@]}"
        return $?
    fi

    if ! pedir_si_no "¿Instalar con sudo los paquetes anteriores?" "s"; then
        return 1
    fi
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${uniq[@]}"
}

qw_asegurar_emulador_terminal() {
    qw_hay_lanzador_terminal && return 0
    msg_aviso "No se detectó un emulador de terminal gráfico usable."
    qw_instalar_emulador_terminal || return 1
    qw_hay_lanzador_terminal
}

qw_lanzar_emulador() {
    # $1=emulador o lanzador, $2=título, $3=comando bash -lc
    local emu="$1" title="$2" wrapped="$3"

    case "$emu" in
        xdg-terminal-exec)
            qw_env_terminal xdg-terminal-exec --title="$title" -- bash -lc "$wrapped" &
            return 0
            ;;
        x-terminal-emulator)
            qw_env_terminal x-terminal-emulator -T "$title" -e bash -lc "$wrapped" &
            return 0
            ;;
        gnome-terminal)
            qw_env_terminal gnome-terminal --title="$title" -- bash -lc "$wrapped" &
            return 0
            ;;
        konsole)
            qw_env_terminal konsole --new-tab -p tabtitle="$title" -e bash -lc "$wrapped" &
            return 0
            ;;
        xfce4-terminal|mate-terminal|lxterminal)
            qw_env_terminal "$emu" --title="$title" -e bash -lc "$wrapped" &
            return 0
            ;;
        tilix|terminator)
            qw_env_terminal "$emu" --title="$title" -e bash -lc "$wrapped" &
            return 0
            ;;
        alacritty)
            qw_env_terminal alacritty --title "$title" -e bash -lc "$wrapped" &
            return 0
            ;;
        kitty)
            qw_env_terminal kitty --title "$title" bash -lc "$wrapped" &
            return 0
            ;;
        xterm)
            qw_env_terminal xterm -fa 'DejaVu Sans Mono' -fs 11 -T "$title" -e bash -lc "$wrapped" &
            return 0
            ;;
        wt.exe)
            wt.exe -w 0 new-tab --title "$title" bash -lc "$wrapped" &
            return 0
            ;;
        *)
            if existe_comando "$emu"; then
                qw_env_terminal "$emu" -e bash -lc "$wrapped" &
                return 0
            fi
            return 1
            ;;
    esac
}

qw_candidatos_terminal() {
    # Orden: terminal del sistema → preferido del usuario → emuladores del escritorio
    [[ -n "${QUICKWHALE_TERMINAL:-}" ]] && printf '%s\n' "$QUICKWHALE_TERMINAL"
    existe_comando xdg-terminal-exec && printf '%s\n' xdg-terminal-exec
    existe_comando x-terminal-emulator && printf '%s\n' x-terminal-emulator
    [[ -n "${TERMINAL:-}" ]] && printf '%s\n' "$TERMINAL"

    local de="${XDG_CURRENT_DESKTOP:-}"
    de="${de,,}"
    case "$de" in
        *gnome*|*unity*|*cinnamon*) printf '%s\n' gnome-terminal ;;
        *kde*|*plasma*)             printf '%s\n' konsole ;;
        *xfce*)                     printf '%s\n' xfce4-terminal ;;
        *mate*)                     printf '%s\n' mate-terminal ;;
        *lxde*|*lxqt*)              printf '%s\n' lxterminal ;;
    esac

    qw_lista_emuladores_conocidos
    existe_comando wt.exe && printf '%s\n' wt.exe
}

qw_build_runner_cmd() {
    local func="$1"
    shift || true
    local cmd
    cmd="$(printf '%q run-activity %q' "$SCRIPT_PATH" "$func")"
    for a in "$@"; do
        cmd+=" "$(printf '%q' "$a")
    done
    printf '%s' "$cmd"
}

qw_intentar_lanzar_candidatos() {
    local title="$1" wrapped="$2" emu
    while IFS= read -r emu; do
        [[ -z "$emu" ]] && continue
        case "$emu" in
            xdg-terminal-exec|x-terminal-emulator|wt.exe)
                qw_lanzar_emulador "$emu" "$title" "$wrapped" && return 0
                ;;
            *)
                qw_emulador_usable "$emu" || continue
                qw_lanzar_emulador "$emu" "$title" "$wrapped" && return 0
                ;;
        esac
    done < <(qw_candidatos_terminal | awk '!seen[$0]++')
    return 1
}

qw_open_terminal() {
    local title="$1"
    local inner_cmd="$2"
    local wrapped

    wrapped="cd $(printf '%q' "$SCRIPT_DIR") && ${inner_cmd}"

    if existe_comando gnome-terminal && ! qw_tiene_dbus; then
        qw_instalar_emulador_terminal 2>/dev/null || true
    fi

    qw_intentar_lanzar_candidatos "$title" "$wrapped" && return 0

    if qw_has_display && qw_instalar_emulador_terminal; then
        qw_intentar_lanzar_candidatos "$title" "$wrapped" && return 0
    fi

    return 1
}

qw_launch() {
    local title="$1"
    local func="$2"

    if ! declare -F "$func" &>/dev/null; then
        msg_error "Actividad no encontrada: $func"
        return 1
    fi

    if [[ "${QUICKWHALE_CHILD:-}" == "1" ]]; then
        "$func" "${@:3}"
        return $?
    fi

    local runner
    runner="$(qw_build_runner_cmd "$func" "${@:3}")"

    if qw_has_display && qw_open_terminal "$title" "$runner"; then
        msg_ok "Actividad abierta en nueva ventana: $title"
        return 0
    fi

    if qw_has_display; then
        msg_aviso "No se pudo abrir una ventana gráfica; ejecutando en esta terminal."
    else
        msg_aviso "Sin entorno gráfico (SSH sin X11); ejecutando en esta terminal."
    fi
    local rc=0
    set +e
    QUICKWHALE_CHILD=1 "$func" "${@:3}"
    rc=$?
    if [[ "$rc" -ne 0 ]]; then
        msg_aviso "La actividad terminó con errores."
    fi
    pausa_obligatoria
    return "$rc"
}

qw_run_activity_child() {
    local func="$1" rc=0
    shift || true
    export QUICKWHALE_CHILD=1
    if declare -F "$func" &>/dev/null; then
        set +e
        "$func" "$@"
        rc=$?
        if [[ "$rc" -ne 0 ]]; then
            echo
            msg_aviso "La actividad terminó con errores."
        fi
    else
        msg_error "Función desconocida: $func"
        rc=1
    fi
    pausa_obligatoria
    return "$rc"
}
