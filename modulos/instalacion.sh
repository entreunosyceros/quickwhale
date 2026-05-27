instalar_docker() {
    requerir_root || return 1
    mostrar_banner
    msg_info "Iniciando instalación de Docker..."

    if existe_comando docker; then
        msg_ok "Docker ya está instalado: $(docker --version)"
        read -r -p "¿Reinstalar/configurar de todos modos? (s/N): " reinstall
        [[ "${reinstall,,}" == "s" ]] || return 0
    fi

    msg_info "Actualizando paquetes del sistema..."
    apt-get update -qq

    msg_info "Instalando dependencias..."
    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common

    msg_info "Añadiendo clave GPG oficial de Docker..."
    install -m 0755 -d /etc/apt/keyrings
    if [[ -f /etc/apt/keyrings/docker.gpg ]]; then
        rm -f /etc/apt/keyrings/docker.gpg
    fi
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    msg_info "Configurando repositorio de Docker..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    msg_info "Instalando Docker Engine, CLI y Compose plugin..."
    apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    # Añadir usuario actual al grupo docker (si se ejecutó con sudo)
    local target_user="${SUDO_USER:-$USER}"
    if [[ -n "$target_user" && "$target_user" != "root" ]]; then
        usermod -aG docker "$target_user" 2>/dev/null || true
        msg_ok "Usuario '$target_user' añadido al grupo 'docker'."
        msg_aviso "Cierra sesión y vuelve a entrar para usar Docker sin sudo."
    fi

    msg_ok "Docker instalado correctamente."
    docker --version
    docker compose version 2>/dev/null || true
}

# =============================================================================
# Instalación de Composer
# =============================================================================

instalar_composer() {
    requerir_root || return 1
    mostrar_banner
    msg_info "Iniciando la instalación de Composer..."

    if existe_comando composer; then
        msg_ok "Composer ya está instalado: $(composer --version 2>/dev/null | head -1)"
        read -r -p "¿Reinstalar? (s/N): " reinstall
        [[ "${reinstall,,}" == "s" ]] || return 0
    fi

    msg_info "Instalando dependencias PHP..."
    apt-get update -qq
    apt-get install -y -qq php-cli php-mbstring php-xml php-zip unzip curl

    msg_info "Descargando instalador oficial de Composer..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "${tmp_dir:-}"' RETURN

    curl -fsSL https://getcomposer.org/installer -o "$tmp_dir/composer-setup.php"
    curl -fsSL https://getcomposer.org/installer.sig -o "$tmp_dir/composer-setup.sig" 2>/dev/null || true

    php "$tmp_dir/composer-setup.php" --install-dir=/usr/local/bin --filename=composer

    chmod +x /usr/local/bin/composer

    msg_ok "Composer instalado correctamente."
    composer --version
}

# =============================================================================
# Instalación completa
# =============================================================================

instalar_comando_global() {
    requerir_root || return 1
    mostrar_banner
    msg_info "Instalando comando global '${INSTALL_BIN##*/}'..."

    if [[ ! -f "$SCRIPT_PATH" ]]; then
        msg_error "No se encuentra el script en: $SCRIPT_PATH"
        return 1
    fi

    ln -sf "$SCRIPT_PATH" "$INSTALL_BIN"
    chmod +x "$INSTALL_BIN"

    msg_ok "Enlace creado: $INSTALL_BIN -> $SCRIPT_PATH"
    msg_info "Ahora puedes ejecutar desde cualquier directorio:"
    echo -e "  ${C_CYAN}quickwhale${C_RESET}"
    echo -e "  ${C_CYAN}quickwhale docker${C_RESET}"
    echo -e "  ${C_CYAN}quickwhale didactic${C_RESET}"
    echo -e "  ${C_DIM}  Módulos en: ${DIR_MODULOS}${C_RESET}"
    echo -e "  ${C_DIM}  Ejemplos en: ${DIR_EJEMPLOS}${C_RESET}"
    echo -e "  ${C_DIM}  Documentación: ${SCRIPT_DIR}/README.md${C_RESET}"
    echo -e "  ${C_DIM}  Configuración LN: ${LN_DIR_CONFIG}${C_RESET}"
}

instalar_emulador_terminal() {
    mostrar_banner
    msg_info "Emulador de terminal para abrir actividades en ventana nueva."
    echo
    if qw_hay_lanzador_terminal; then
        msg_ok "Ya hay un lanzador de terminal disponible."
        msg_info "Prioridad: x-terminal-emulator / xdg-terminal-exec → emulador del escritorio."
        msg_info "Variable opcional: export QUICKWHALE_TERMINAL=gnome-terminal"
    fi
    echo
    if qw_instalar_emulador_terminal; then
        msg_ok "Dependencias de terminal instaladas o ya presentes."
    else
        msg_aviso "No se instalaron paquetes. Las actividades usarán esta terminal."
    fi
}

instalar_todo() {
    verificar_ubuntu
    instalar_docker
    echo
    instalar_composer
    echo
    instalar_comando_global
    echo
    msg_ok "Instalación completa finalizada correctamente."
    msg_info "Proyecto de ejemplo Compose: $DIR_EJEMPLOS"
    pausa
}
