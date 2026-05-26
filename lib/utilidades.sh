requerir_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        msg_error "Esta operación requiere permisos de administrador (sudo)."
        msg_info "Ejecuta: sudo $0"
        exit 1
    fi
}

existe_comando() {
    command -v "$1" &>/dev/null
}

es_ubuntu() {
    [[ -f /etc/os-release ]] && grep -qi 'ubuntu' /etc/os-release
}

es_afirmativo() {
    local r="${1:-}"
    r="${r,,}"
    [[ "$r" == "s" || "$r" == "si" || "$r" == "sí" || "$r" == "y" || "$r" == "yes" ]]
}

qw_mostrar_url_clicable() {
    local url="$1"
    local etiqueta="${2:-$url}"
    printf '\e]8;;%s\a%s\e]8;;\a\n' "$url" "$etiqueta"
}

qw_abrir_url() {
    local url="$1"
    if existe_comando xdg-open; then
        xdg-open "$url" >/dev/null 2>&1 &
    elif existe_comando sensible-browser; then
        sensible-browser "$url" >/dev/null 2>&1 &
    elif existe_comando gio; then
        gio open "$url" >/dev/null 2>&1 &
    elif existe_comando open; then
        open "$url" >/dev/null 2>&1 &
    elif existe_comando cmd.exe; then
        cmd.exe /c start "" "$url" >/dev/null 2>&1 &
    else
        msg_error "No se pudo abrir el navegador. Abre manualmente: $url"
        return 1
    fi
    return 0
}

qw_expandir_ruta() {
    local p="${1:-}"
    [[ -n "$p" ]] || { echo "$p"; return 1; }

    case "$p" in
        "~") p="$HOME" ;;
        "~/"*) p="${HOME}/${p:2}" ;;
        "~"*) p="${p/#\~/$HOME}" ;;
    esac

    if [[ -e "$p" ]]; then
        readlink -f "$p" 2>/dev/null && return 0
    fi
    readlink -m "$p" 2>/dev/null || echo "$p"
}

verificar_ubuntu() {
    if ! es_ubuntu; then
        msg_aviso "Este script está optimizado para Ubuntu. Continúas bajo tu responsabilidad."
        read -r -p "¿Deseas continuar? (s/N): " confirm
        [[ "${confirm,,}" == "s" ]] || exit 0
        return
    fi
    local ver
    ver=$(grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"')
    msg_info "Ubuntu detectado: $ver"
}
