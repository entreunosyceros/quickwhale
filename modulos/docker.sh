verificar_docker() {
    if ! existe_comando docker; then
        msg_error "Docker no está instalado. Usa la opción de instalación del menú principal."
        pausa_obligatoria
        return 1
    fi

    if qw_asegurar_docker_cli || docker info &>/dev/null; then
        return 0
    fi

    if ! docker info &>/dev/null; then
        case "$(qw_diagnostico_fallo_docker)" in
            contexto_desktop)
                msg_error "Docker Engine está activo, pero no se pudo cambiar el contexto del CLI."
                if pedir_si_no "¿Intentar de nuevo (docker context use default)?" "s"; then
                    qw_corregir_contexto_docker_engine && docker info &>/dev/null && return 0
                fi
                ;;
            servicio_o_otro)
                if ! qw_servicio_docker_activo; then
                    msg_error "Docker no responde y el servicio no está activo."
                    msg_info "Menú principal → 4 → 2 (iniciar Docker)."
                else
                    msg_error "Docker no responde."
                    msg_info "Menú principal → 4 (Estado y servicios) para diagnosticar."
                fi
                ;;
            *)
                msg_error "Docker está instalado y el servicio systemd está activo, pero tu usuario no puede usarlo."
                if ! qw_usuario_en_grupo_docker; then
                    msg_info "Causa probable: no estás en el grupo 'docker'."
                    msg_info "Menú principal → 4 → 6 (añadir al grupo docker), luego cierra sesión."
                else
                    msg_info "Menú principal → 4 → 7 (contexto default) o cierra sesión."
                fi
                ;;
        esac
        pausa_obligatoria
        return 1
    fi
    return 0
}

# =============================================================================
# Helpers Docker
# =============================================================================

pedir_contenedor() {
    local running_only="${1:-false}"
    echo
    msg_info "Contenedores disponibles:"
    if [[ "$running_only" == "true" ]]; then
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
    echo
    read -r -p "Nombre o ID del contenedor: " container
    [[ -n "$container" ]] || { msg_error "Debes indicar un contenedor."; return 1; }
    echo "$container"
}

pedir_imagen() {
    echo
    msg_info "Imágenes disponibles:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
    echo
    read -r -p "Nombre de imagen (ej: nginx:latest): " image
    [[ -n "$image" ]] || { msg_error "Debes indicar una imagen."; return 1; }
    echo "$image"
}

pedir_carpeta_compose() {
    local default_dir="${PWD}"
    read -r -p "Directorio del proyecto [$default_dir]: " dir
    dir="${dir:-$default_dir}"
    dir="$(qw_expandir_ruta "$dir")"
    if [[ ! -f "$dir/docker-compose.yml" && ! -f "$dir/docker-compose.yaml" \
        && ! -f "$dir/compose.yml" && ! -f "$dir/compose.yaml" ]]; then
        msg_aviso "No se encontró compose en '$dir'."
        read -r -p "¿Continuar de todos modos? (s/N): " c
        [[ "${c,,}" == "s" ]] || return 1
    fi
    echo "$dir"
}

ejecutar_compose() {
    local dir action extra_args
    dir=$(pedir_carpeta_compose) || return 1
    action="$1"
    shift
    extra_args=("$@")
    msg_info "Ejecutando: docker compose -f \"$dir\" $action ${extra_args[*]:-}"
    (cd "$dir" && docker compose "${extra_args[@]}" "$action")
}

# =============================================================================
# Operaciones Docker (menú)
# =============================================================================

op_list_containers() {
    verificar_docker || return
    mostrar_banner
    echo -e "${C_BOLD}Contenedores${C_RESET}"
    echo "  1) Solo en ejecución"
    echo "  2) Todos (incluidos detenidos)"
    read -r -p "Opción [1]: " opt
    opt="${opt:-1}"
    case "$opt" in
        1) docker ps ;;
        2) docker ps -a ;;
        *) msg_error "Opción inválida." ;;
    esac
    pausa
}

op_list_images() {
    verificar_docker || return
    mostrar_banner
    docker images
    pausa
}

op_start_container() {
    verificar_docker || return
    mostrar_banner
    local c
    c=$(pedir_contenedor false) || { pausa; return; }
    docker start "$c" && msg_ok "Contenedor '$c' iniciado."
    pausa
}

op_stop_container() {
    verificar_docker || return
    mostrar_banner
    local c
    c=$(pedir_contenedor true) || { pausa; return; }
    docker stop "$c" && msg_ok "Contenedor '$c' detenido."
    pausa
}

op_restart_container() {
    verificar_docker || return
    mostrar_banner
    local c
    c=$(pedir_contenedor true) || { pausa; return; }
    docker restart "$c" && msg_ok "Contenedor '$c' reiniciado."
    pausa
}

op_logs_container() {
    verificar_docker || return
    mostrar_banner
    local c lines follow
    c=$(pedir_contenedor true) || { pausa; return; }
    read -r -p "Número de líneas [100]: " lines
    lines="${lines:-100}"
    read -r -p "¿Seguir en tiempo real? (s/N): " follow
    if [[ "${follow,,}" == "s" ]]; then
        docker logs -f --tail "$lines" "$c"
    else
        docker logs --tail "$lines" "$c"
    fi
    pausa
}

op_exec_container() {
    verificar_docker || return
    mostrar_banner
    local c shell
    c=$(pedir_contenedor true) || { pausa; return; }
    read -r -p "Shell [/bin/bash]: " shell
    shell="${shell:-/bin/bash}"
    msg_info "Entrando en '$c' con $shell (escribe 'exit' para salir)..."
    docker exec -it "$c" "$shell"
    pausa
}

op_run_container() {
    verificar_docker || return
    mostrar_banner
    local image name ports detach
    image=$(pedir_imagen) || { pausa; return; }
    read -r -p "Nombre del contenedor (opcional): " name
    read -r -p "Puertos (-p host:container, ej: 8080:80, vacío=ninguno): " ports
    read -r -p "¿Ejecutar en segundo plano (-d)? (s/N): " detach

    local cmd=(docker run)
    [[ "${detach,,}" == "s" ]] && cmd+=(-d)
    [[ -n "$name" ]] && cmd+=(--name "$name")
    if [[ -n "$ports" ]]; then
        IFS=',' read -ra port_list <<< "$ports"
        for p in "${port_list[@]}"; do
            cmd+=(-p "$(echo "$p" | xargs)")
        done
    fi
    cmd+=("$image")

    read -r -p "Comando adicional (vacío=por defecto de la imagen): " extra
    [[ -n "$extra" ]] && cmd+=($extra)

    msg_info "Ejecutando: ${cmd[*]}"
    "${cmd[@]}"
    pausa
}

op_remove_container() {
    verificar_docker || return
    mostrar_banner
    local c force
    c=$(pedir_contenedor false) || { pausa; return; }
    read -r -p "¿Forzar eliminación (-f)? (s/N): " force
    if [[ "${force,,}" == "s" ]]; then
        docker rm -f "$c"
    else
        docker stop "$c" 2>/dev/null || true
        docker rm "$c"
    fi
    msg_ok "Contenedor '$c' eliminado."
    pausa
}

docker_list() {
    # Definición de colores para mejorar la legibilidad
    local VERDE='\033[0;32m'
    local AZUL='\033[0;34m'
    local CIAN='\033[0;36m'
    local AMARILLO='\033[1;33m'
    local RESET='\033[0m'

    echo -e "${AMARILLO}====================================================${RESET}"
    echo -e "${AMARILLO}     LISTADO DE IMÁGENES PARA DOCKER                ${RESET}"
    echo -e "${AMARILLO}====================================================${RESET}"

    # 1. Bases de Datos y Almacenamiento
    echo -e "\n${AMARILLO}[ Bases de Datos y Almacenamiento ]${RESET}"
    echo -e "  ${VERDE}postgres${RESET}                   - PostgreSQL: Base de datos relacional robusta."
    echo -e "  ${VERDE}mysql${RESET}                      - MySQL: Una de las opciones más utilizadas para la web."
    echo -e "  ${VERDE}redis${RESET}                      - Redis: Almacenamiento en memoria para caché y colas."

    # 2. Desarrollo Web y Servidores
    echo -e "\n${AMARILLO}[ Desarrollo Web y Servidores ]${RESET}"
    echo -e "  ${VERDE}nginx${RESET}                      - Nginx: Servidor web ultraligero y proxy inverso."
    echo -e "  ${VERDE}wordpress${RESET}                  - WordPress: Gestión de contenidos (requiere base de datos)."
    echo -e "  ${VERDE}python${RESET}                     - Python: Para ejecutar scripts o microservicios."
    echo -e "  ${VERDE}node${RESET}                       - Node.js: Entorno de ejecución para JavaScript en backend. (¡Popular!)"

    # 3. Inteligencia Artificial y Ciencia de Datos
    echo -e "\n${AMARILLO}[ Inteligencia Artificial y Ciencia de Datos ]${RESET}"
    echo -e "  ${VERDE}jupyter/datascience-notebook${RESET} - Jupyter Notebook: Pila de datos preconfigurada."
    echo -e "  ${VERDE}ollama/ollama${RESET}              - Ollama: Ejecución de modelos de lenguaje (LLMs) localmente."

    # 4. Herramientas de Red y Laboratorio Doméstico
    echo -e "\n${AMARILLO}[ Herramientas de Red y Laboratorio Doméstico (Homelab) ]${RESET}"
    echo -e "  ${VERDE}portainer/portainer-ce${RESET}     - Portainer: Interfaz gráfica para gestionar contenedores."
    echo -e "  ${VERDE}pihole/pihole${RESET}              - Pi-hole: Bloqueador de publicidad a nivel de red."
    echo -e "  ${VERDE}homeassistant/home-assistant${RESET} - Home Assistant: Automatización del hogar."

    # 5. Ciberseguridad y Auditoría
    echo -e "\n${AMARILLO}[ Ciberseguridad y Auditoría ]${RESET}"
    echo -e "  ${VERDE}metasploitframework/metasploit-framework${RESET} - Metasploit: Pruebas de intrusión."

    # 6. Utilidades del Sistema y Orquestación (Agregadas por popularidad)
    echo -e "\n${AMARILLO}[ Sistema y Orquestación Populares ]${RESET}"
    echo -e "  ${VERDE}alpine${RESET}                     - Alpine Linux: Imagen base minimalista y ultraligera (~5MB)."
    echo -e "  ${VERDE}traefik${RESET}                    - Traefik: Proxy inverso moderno y enrutador nativo de la nube."

    echo -e "\n${AMARILLO}====================================================${RESET}"
}

op_pull_image() {
    verificar_docker || return
    mostrar_banner
    docker_list
    local image
    image=$(pedir_imagen) || { pausa; return; }
    docker pull "$image"
    msg_ok "Imagen '$image' descargada."
    pausa
}

op_build_image() {
    verificar_docker || return
    mostrar_banner
    local dir tag
    read -r -p "Directorio con Dockerfile [.]: " dir
    dir="${dir:-.}"
    dir="$(qw_expandir_ruta "$dir")"
    read -r -p "Etiqueta de imagen (ej: miapp:1.0): " tag
    [[ -n "$tag" ]] || { msg_error "Debes indicar una etiqueta."; pausa; return; }
    docker build -t "$tag" "$dir"
    msg_ok "Imagen '$tag' construida."
    pausa
}

op_remove_image() {
    verificar_docker || return
    mostrar_banner
    local image force
    image=$(pedir_imagen) || { pausa; return; }
    read -r -p "¿Forzar (-f)? (s/N): " force
    if [[ "${force,,}" == "s" ]]; then
        docker rmi -f "$image"
    else
        docker rmi "$image"
    fi
    msg_ok "Imagen '$image' eliminada."
    pausa
}

op_compose_up() {
    verificar_docker || return
    mostrar_banner
    local dir detached
    dir=$(pedir_carpeta_compose) || { pausa; return; }
    read -r -p "¿En segundo plano (-d)? (S/n): " detached
    if [[ "${detached,,}" != "n" ]]; then
        (cd "$dir" && docker compose up -d)
    else
        (cd "$dir" && docker compose up)
    fi
    msg_ok "docker compose up ejecutado en '$dir'."
    pausa
}

op_compose_down() {
    verificar_docker || return
    mostrar_banner
    local dir
    dir=$(pedir_carpeta_compose) || { pausa; return; }
    read -r -p "¿Eliminar volúmenes (-v)? (s/N): " vol
    if [[ "${vol,,}" == "s" ]]; then
        (cd "$dir" && docker compose down -v)
    else
        (cd "$dir" && docker compose down)
    fi
    msg_ok "docker compose down ejecutado."
    pausa
}

op_compose_ps() {
    verificar_docker || return
    mostrar_banner
    local dir
    dir=$(pedir_carpeta_compose) || { pausa; return; }
    (cd "$dir" && docker compose ps)
    pausa
}

op_compose_logs() {
    verificar_docker || return
    mostrar_banner
    local dir service follow
    dir=$(pedir_carpeta_compose) || { pausa; return; }
    read -r -p "Servicio específico (vacío=todos): " service
    read -r -p "¿Seguir logs (-f)? (s/N): " follow
    local cmd=(docker compose logs --tail=100)
    [[ "${follow,,}" == "s" ]] && cmd+=(-f)
    [[ -n "$service" ]] && cmd+=("$service")
    (cd "$dir" && "${cmd[@]}")
    pausa
}

op_system_prune() {
    verificar_docker || return
    mostrar_banner
    msg_aviso "Esto eliminará contenedores detenidos, redes no usadas e imágenes huérfanas."
    read -r -p "¿Continuar? (s/N): " confirm
    [[ "${confirm,,}" == "s" ]] || return
    read -r -p "¿Incluir volúmenes no usados? (s/N): " vol
    if [[ "${vol,,}" == "s" ]]; then
        docker system prune -af --volumes
    else
        docker system prune -af
    fi
    msg_ok "Limpieza completada."
    pausa
}

op_docker_status() {
    mostrar_banner
    echo -e "${C_BOLD}Estado del entorno${C_RESET}"
    echo
    if existe_comando docker; then
        qw_mostrar_diagnostico_docker
        if qw_docker_accesible; then
            docker compose version 2>/dev/null && true
        fi
    else
        echo -e "  Docker: ${C_RED}no instalado${C_RESET}"
    fi
    echo
    if existe_comando composer; then
        echo -e "  Composer: ${C_GREEN}$(qw_composer_version)${C_RESET}"
    else
        echo -e "  Composer: ${C_RED}no instalado${C_RESET}"
    fi
    echo
    if [[ -L "$INSTALL_BIN" ]] && existe_comando quickwhale; then
        echo -e "  Comando global: ${C_GREEN}quickwhale -> $(readlink -f "$INSTALL_BIN")${C_RESET}"
    else
        echo -e "  Comando global: ${C_YELLOW}no instalado${C_RESET}"
        echo -e "  ${C_DIM}  Para instalarlo: menú principal → 1 (Instalación) → 4${C_RESET}"
        echo -e "  ${C_DIM}  O ejecuta: sudo ${SCRIPT_PATH} link${C_RESET}"
        echo
        if pedir_si_no "¿Instalar el comando global quickwhale ahora? (requiere sudo)" "s"; then
            if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
                instalar_comando_global
            else
                msg_info "Vuelve a lanzar esta ventana con sudo o ejecuta:"
                echo -e "  ${C_CYAN}sudo ${SCRIPT_PATH} link${C_RESET}"
            fi
        fi
    fi
    echo -e "  Ejemplo Compose: ${C_DIM}$DIR_EJEMPLOS${C_RESET}"
    if declare -F qw_obtener_proyecto_activo &>/dev/null; then
        local _ap
        _ap="$(qw_obtener_proyecto_activo)"
        echo -e "  Proyecto activo: ${C_CYAN}${_ap:-ninguno}${C_RESET}"
        echo -e "  Mis proyectos: ${C_DIM}${DIR_PROYECTOS}${C_RESET}"
    fi
    echo
    pausa
}
