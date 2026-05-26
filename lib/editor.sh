# Editor de archivos (YAML, HTML, Dockerfile, etc.)

qw_resolver_editor() {
    if [[ -n "${QUICKWHALE_EDITOR:-}" ]]; then
        echo "$QUICKWHALE_EDITOR"
        return 0
    fi
    if [[ -n "${EDITOR:-}" ]]; then
        echo "$EDITOR"
        return 0
    fi
    local e
    for e in nano vim vi micro code codium; do
        if command -v "$e" &>/dev/null; then
            echo "$e"
            return 0
        fi
    done
    echo "nano"
}

qw_editar_archivo() {
    local file="${1:?falta archivo}"
    local editor
    editor="$(qw_resolver_editor)"

    if [[ ! -f "$file" ]]; then
        msg_error "Archivo no encontrado: $file"
        return 1
    fi

    msg_info "Editando: $file"
    msg_info "Editor: $editor (exporta QUICKWHALE_EDITOR o EDITOR para cambiarlo)"

    case "$editor" in
        code|codium)
            "$editor" -w "$file"
            ;;
        *)
            # shellcheck disable=SC2086
            $editor "$file"
            ;;
    esac
}

qw_elegir_de_lista() {
    # Uso: qw_elegir_de_lista "Titulo" array_name
    # Rellena QW_RESULTADO_ELECCION con la ruta elegida
    local title="$1"
    local -n _items=$2
    local i choice

    QW_RESULTADO_ELECCION=""

    if [[ ${#_items[@]} -eq 0 ]]; then
        msg_aviso "No hay elementos en la lista."
        return 1
    fi

    echo
    echo -e "${C_BOLD}${title}${C_RESET}"
    for i in "${!_items[@]}"; do
        echo "  $((i + 1))) ${_items[$i]}"
    done
    echo "  0) Cancelar"
    echo
    read -r -p "Opción: " choice
    [[ "$choice" == "0" ]] && return 1
    [[ "$choice" =~ ^[0-9]+$ ]] || { msg_error "Opción inválida."; return 1; }
    (( choice >= 1 && choice <= ${#_items[@]} )) || { msg_error "Opción fuera de rango."; return 1; }
    QW_RESULTADO_ELECCION="${_items[$((choice - 1))]}"
    return 0
}
