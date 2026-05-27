requerir_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        msg_error "Esta operación requiere permisos de administrador (sudo)."
        msg_info "Ejecuta: sudo ${SCRIPT_PATH:-$0}"
        pausa_obligatoria
        return 1
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

qw_es_root() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]]
}

# Usuario no root (el que lanzó sudo, o $USER si no hay sudo)
qw_usuario_real() {
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        echo "$SUDO_USER"
    elif ! qw_es_root; then
        echo "$USER"
    fi
}

qw_home_usuario() {
    local u="${1:-$(qw_usuario_real)}"
    [[ -n "$u" ]] || return 1
    eval echo "~$u"
}

# Composer no debe ejecutarse como root en proyectos (solo self-update global puede requerirlo)
qw_ejecutar_composer() {
    local u home
    if qw_es_root; then
        u="$(qw_usuario_real)"
        if [[ -z "$u" ]]; then
            msg_error "Composer no debe ejecutarse como root."
            msg_info "Sal de sudo y ejecuta QuickWhale sin root: ./quickwhale.sh"
            return 1
        fi
        home="$(qw_home_usuario "$u")"
        msg_aviso "Ejecutando Composer como usuario '$u' (no como root)."
        sudo -u "$u" -H env HOME="$home" composer "$@"
    else
        composer "$@"
    fi
}

qw_composer_version() {
    qw_ejecutar_composer --version 2>/dev/null | head -1
}

qw_ejecutar_composer_self_update() {
    msg_info "Actualizando Composer global..."
    if qw_es_root; then
        COMPOSER_ALLOW_SUPERUSER=1 composer self-update
    elif composer self-update 2>/dev/null; then
        :
    else
        msg_info "Se requiere sudo para actualizar el Composer del sistema."
        sudo env COMPOSER_ALLOW_SUPERUSER=1 composer self-update
    fi
}
