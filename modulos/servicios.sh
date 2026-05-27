# Estado del entorno y gestión de servicios (Docker / Composer)

qw_usuario_en_grupo_docker() {
    local u="${1:-${SUDO_USER:-$USER}}"
    groups "$u" 2>/dev/null | grep -qw docker
}

qw_servicio_docker_activo() {
    existe_comando systemctl && [[ "$(systemctl is-active docker 2>/dev/null)" == "active" ]]
}

qw_docker_accesible() {
    existe_comando docker && docker info &>/dev/null
}

qw_contexto_docker_activo() {
    docker context show 2>/dev/null | awk 'NF {print $1; exit}'
}

# Comprueba el Engine instalado con systemd (socket /var/run/docker.sock)
qw_docker_engine_accesible() {
    DOCKER_CONTEXT=default docker info &>/dev/null
}

qw_diagnostico_fallo_docker() {
    docker info &>/dev/null && { echo "ok"; return; }

    local err ctx
    err=$(docker info 2>&1)
    ctx="$(qw_contexto_docker_activo)"

    if [[ "$ctx" == "desktop-linux" ]] || grep -qiE 'desktop/docker\.sock' <<< "$err"; then
        if qw_docker_engine_accesible; then
            echo "contexto_desktop"
            return
        fi
    fi

    if grep -qi 'permission denied' <<< "$err"; then
        echo "permisos"
        return
    fi

    if qw_servicio_docker_activo && qw_docker_engine_accesible; then
        echo "contexto_desktop"
        return
    fi

    if qw_servicio_docker_activo; then
        echo "permisos_o_grupo"
        return
    fi

    echo "servicio_o_otro"
}

qw_corregir_contexto_docker_engine() {
    if ! existe_comando docker; then
        msg_error "Docker no está instalado."
        return 1
    fi
    msg_info "Cambiando contexto a 'default' (Docker Engine: /var/run/docker.sock)..."
    if docker context use default 2>/dev/null; then
        msg_ok "Contexto activo: default"
        if docker info &>/dev/null; then
            msg_ok "docker info responde correctamente."
            return 0
        fi
        msg_aviso "Contexto cambiado, pero docker info sigue fallando."
        qw_mostrar_diagnostico_docker
        return 1
    fi
    msg_error "No se pudo ejecutar: docker context use default"
    return 1
}

# Si el Engine responde pero el CLI apunta a Docker Desktop, cambia a 'default' solo
qw_asegurar_docker_cli() {
    docker info &>/dev/null && return 0

    if [[ "$(qw_diagnostico_fallo_docker)" != "contexto_desktop" ]]; then
        return 1
    fi
    if ! qw_docker_engine_accesible; then
        return 1
    fi

    msg_info "El CLI usaba Docker Desktop; cambiando a Docker Engine (contexto 'default')..."
    if docker context use default 2>/dev/null && docker info &>/dev/null; then
        msg_ok "Contexto Docker listo para QuickWhale."
        return 0
    fi
    return 1
}

qw_explicar_fallo_docker_tras_servicio() {
    local diag="$1"
    case "$diag" in
        contexto_desktop)
            msg_ok "Servicio Docker Engine (systemd): activo."
            msg_aviso "El CLI usa el contexto '$(qw_contexto_docker_activo)' (Docker Desktop), que no está en marcha."
            msg_info "QuickWhale trabaja con Docker Engine del sistema, no con Docker Desktop."
            if pedir_si_no "¿Cambiar al contexto 'default' ahora?" "s"; then
                qw_corregir_contexto_docker_engine
            else
                msg_info "Manual: docker context use default"
            fi
            ;;
        permisos|permisos_o_grupo)
            msg_aviso "El servicio está activo, pero tu usuario no puede usar el socket de Docker."
            if ! qw_usuario_en_grupo_docker; then
                msg_info "Solución: opción 6 (grupo docker) → cerrar sesión o 'newgrp docker'."
            else
                msg_info "Estás en el grupo docker; prueba cerrar sesión o opción 7 (contexto default)."
            fi
            ;;
        *)
            msg_aviso "El servicio arrancó pero 'docker info' aún falla."
            qw_mostrar_diagnostico_docker
            ;;
    esac
}

# Muestra por qué docker info falla aunque el servicio esté activo
qw_mostrar_diagnostico_docker() {
    local u="${SUDO_USER:-$USER}"
    local svc="desconocido"

    if ! existe_comando docker; then
        echo -e "  Docker CLI: ${C_RED}no instalado${C_RESET}"
        return
    fi

    echo -e "  Docker CLI: ${C_GREEN}$(docker --version 2>/dev/null)${C_RESET}"

    if existe_comando systemctl; then
        svc="$(systemctl is-active docker 2>/dev/null || echo desconocido)"
        if [[ "$svc" == "active" ]]; then
            echo -e "  Servicio systemd: ${C_GREEN}activo${C_RESET} (docker.service corre)"
        else
            echo -e "  Servicio systemd: ${C_YELLOW}${svc}${C_RESET}"
        fi
    fi

    if qw_docker_accesible; then
        echo -e "  Acceso desde tu usuario: ${C_GREEN}OK${C_RESET} (docker info funciona)"
        echo -e "  ${C_DIM}  Contexto activo: $(qw_contexto_docker_activo)${C_RESET}"
        return
    fi

    echo -e "  Acceso desde tu usuario: ${C_RED}sin acceso${C_RESET} (docker info falla)"
    echo -e "  ${C_DIM}  Contexto activo: $(qw_contexto_docker_activo)${C_RESET}"

    case "$(qw_diagnostico_fallo_docker)" in
        contexto_desktop)
            echo -e "  ${C_YELLOW}  Causa: contexto Docker Desktop; el Engine del sistema sí responde.${C_RESET}"
            echo -e "  ${C_DIM}  Solución: opción 7 → usar contexto 'default'${C_RESET}"
            return
            ;;
    esac

    if qw_servicio_docker_activo; then
        echo -e "  ${C_DIM}  El servicio está activo, pero tu usuario no puede hablar con el daemon.${C_RESET}"
        if ! qw_usuario_en_grupo_docker "$u"; then
            echo -e "  ${C_YELLOW}  Causa probable: '$u' no está en el grupo 'docker'.${C_RESET}"
            echo -e "  ${C_DIM}  Solución: opción 6 → cerrar sesión o 'newgrp docker'${C_RESET}"
        else
            echo -e "  ${C_DIM}  Estás en el grupo docker; prueba cerrar sesión o reiniciar (opción 4).${C_RESET}"
        fi
    else
        echo -e "  ${C_DIM}  Solución: opción 2 (iniciar servicio Docker).${C_RESET}"
    fi
}

qw_estado_docker_breve() {
    qw_mostrar_diagnostico_docker
}

qw_estado_composer_breve() {
    if existe_comando composer; then
        echo -e "  Composer: ${C_GREEN}$(qw_composer_version)${C_RESET}"
    else
        echo -e "  Composer: ${C_RED}no instalado${C_RESET}"
    fi
    if qw_es_root; then
        echo -e "  ${C_DIM}  QuickWhale en sudo: Composer se usa como '$(qw_usuario_real)'${C_RESET}"
    fi
    echo -e "  ${C_DIM}  (Composer es una herramienta CLI, no un servicio del sistema)${C_RESET}"
}

op_docker_servicio() {
    local accion="${1:?falta acción}"
    if ! existe_comando systemctl; then
        msg_error "systemctl no está disponible en este sistema."
        pausa_obligatoria
        return 1
    fi

    mostrar_banner

    case "$accion" in
        stop)
            msg_aviso "Se detendrá el daemon Docker (contenedores en ejecución se pararán)."
            pedir_si_no "¿Continuar?" "N" || return 0
            ;;
    esac

    msg_info "Ejecutando: sudo systemctl $accion docker"
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        systemctl "$accion" docker
    else
        sudo systemctl "$accion" docker
    fi
    local rc=$?

    if [[ "$accion" == "status" ]]; then
        pausa
        return $rc
    fi

    if [[ $rc -eq 0 ]]; then
        msg_ok "systemctl $accion docker — OK"
        if docker info &>/dev/null; then
            msg_ok "Docker responde correctamente."
        elif [[ "$accion" == "start" || "$accion" == "restart" ]]; then
            qw_explicar_fallo_docker_tras_servicio "$(qw_diagnostico_fallo_docker)"
        fi
    else
        msg_error "Falló systemctl $accion docker (código $rc)."
    fi
    pausa
    return $rc
}

op_docker_usar_contexto_engine() {
    mostrar_banner
    echo -e "${C_BOLD}Contexto Docker${C_RESET}"
    echo
    echo -e "  Contexto actual: ${C_CYAN}$(qw_contexto_docker_activo)${C_RESET}"
    echo -e "  ${C_DIM}  'default' = Docker Engine (systemd, /var/run/docker.sock)${C_RESET}"
    echo -e "  ${C_DIM}  'desktop-linux' = Docker Desktop (aplicación aparte)${C_RESET}"
    echo
  if [[ "$(qw_contexto_docker_activo)" == "default" ]] && docker info &>/dev/null; then
        msg_ok "Ya usas el contexto correcto y docker info funciona."
        pausa
        return 0
    fi
    qw_corregir_contexto_docker_engine
    pausa
}

op_docker_permisos_grupo() {
    mostrar_banner
    local user="${SUDO_USER:-$USER}"

    if qw_usuario_en_grupo_docker "$user"; then
        msg_ok "El usuario '$user' ya pertenece al grupo 'docker'."
        msg_info "Si sigue sin funcionar, cierra sesión y vuelve a entrar."
        pausa
        return 0
    fi

    msg_info "Añadiendo '$user' al grupo 'docker' (requiere sudo)..."
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        usermod -aG docker "$user"
    else
        sudo usermod -aG docker "$user"
    fi

    if qw_usuario_en_grupo_docker "$user"; then
        msg_ok "Usuario añadido al grupo 'docker'."
    else
        msg_ok "Cambio aplicado (puede requerir cerrar sesión)."
    fi
    msg_aviso "Cierra sesión y vuelve a entrar, o ejecuta: newgrp docker"
    pausa
}

op_composer_verificar() {
    mostrar_banner
    echo -e "${C_BOLD}Verificación de Composer${C_RESET}"
    echo

    if existe_comando php; then
        echo -e "  PHP: ${C_GREEN}$(php --version 2>/dev/null | head -1)${C_RESET}"
    else
        echo -e "  PHP: ${C_RED}no encontrado${C_RESET}"
        msg_info "Instala PHP: menú principal → 1 → 2 (Instalar Composer)."
    fi

    if ! existe_comando composer; then
        echo -e "  Composer: ${C_RED}no instalado${C_RESET}"
        pausa
        return 1
    fi

    echo -e "  Composer: ${C_GREEN}$(qw_composer_version)${C_RESET}"
    if qw_es_root; then
        echo -e "  ${C_DIM}  (diagnóstico como usuario '$(qw_usuario_real)', no como root)${C_RESET}"
    fi
    echo
    msg_info "Diagnóstico (composer diagnose):"
    qw_ejecutar_composer diagnose 2>&1 | head -30
    echo
    pausa
}

op_composer_actualizar() {
    mostrar_banner
    if ! existe_comando composer; then
        msg_error "Composer no está instalado."
        pausa_obligatoria
        return 1
    fi
    msg_info "Actualizando Composer (self-update)..."
    qw_ejecutar_composer_self_update
    msg_ok "Composer actualizado."
    qw_composer_version
    pausa
}

op_composer_limpiar_cache() {
    mostrar_banner
    if ! existe_comando composer; then
        msg_error "Composer no está instalado."
        pausa_obligatoria
        return 1
    fi
    msg_info "Limpiando caché de Composer..."
    qw_ejecutar_composer clear-cache
    msg_ok "Caché limpiada."
    pausa
}

op_composer_reinstalar() {
    mostrar_banner
    msg_info "Reinstalar Composer (menú Instalación)."
    instalar_composer
}

menu_estado_y_servicios() {
    while true; do
        mostrar_banner
        echo -e "${C_BOLD}Estado y servicios${C_RESET}"
        echo -e "${C_DIM}  Gestiona el servicio Docker y comprueba Composer.${C_RESET}"
        echo
        qw_estado_docker_breve
        qw_estado_composer_breve
        echo
        echo "   1) Ver estado completo del entorno"
        echo
        echo "  --- Servicio Docker (systemd) ---"
        echo "   2) Iniciar Docker"
        echo "   3) Parar Docker"
        echo "   4) Reiniciar Docker"
        echo "   5) Ver servicio systemd (systemctl status docker)"
        echo "   6) Añadir mi usuario al grupo docker (sudo)"
        echo "   7) Usar contexto Docker Engine (default, no Desktop)"
        echo
        echo "  --- Composer (herramienta, no servicio) ---"
        echo "   8) Verificar Composer (diagnóstico)"
        echo "   9) Actualizar Composer (self-update)"
        echo "  10) Limpiar caché de Composer"
        echo "  11) Reinstalar Composer (sudo)"
        echo
        echo "   0) Volver"
        echo
        read -r -p "Selecciona una opción: " choice
        case "$choice" in
            1)  op_docker_status ;;
            2)  op_docker_servicio start ;;
            3)  op_docker_servicio stop ;;
            4)  op_docker_servicio restart ;;
            5)  op_docker_servicio status ;;
            6)  op_docker_permisos_grupo ;;
            7)  op_docker_usar_contexto_engine ;;
            8)  op_composer_verificar ;;
            9)  op_composer_actualizar ;;
            10) op_composer_limpiar_cache ;;
            11) op_composer_reinstalar ;;
            0)  return ;;
            *)  msg_error "Opción no válida."; pausa ;;
        esac
    done
}
