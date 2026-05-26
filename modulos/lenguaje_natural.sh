# Modo lenguaje natural — motor + menú
# Las frases editables están en: configuracion/lenguaje_natural/intenciones.conf

declare -gA LN_META_LABEL LN_META_CMD LN_META_PRIORITY LN_PATRONES
declare -ga LN_INTENT_ORDER=()
LN_INTENTS_LOADED=0

ln_invalidar_cache() {
    LN_INTENTS_LOADED=0
    LN_INTENT_ORDER=()
    unset LN_META_LABEL LN_META_CMD LN_META_PRIORITY LN_PATRONES
    declare -gA LN_META_LABEL LN_META_CMD LN_META_PRIORITY LN_PATRONES
}

ln_fold_accents() {
    local s="$1"
    s="${s//á/a}"; s="${s//à/a}"; s="${s//ä/a}"
    s="${s//é/e}"; s="${s//è/e}"; s="${s//ë/e}"
    s="${s//í/i}"; s="${s//ì/i}"; s="${s//ï/i}"
    s="${s//ó/o}"; s="${s//ò/o}"; s="${s//ö/o}"
    s="${s//ú/u}"; s="${s//ù/u}"; s="${s//ü/u}"
    echo "$s"
}

ln_normalize() {
    local s="${1:-}"
    s="${s,,}"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    ln_fold_accents "$s"
}

# Siempre espera Enter (pausa() del UI no hace nada en ventana hija QUICKWHALE_CHILD)
ln_pause() {
    echo
    read -r -p "Pulsa Enter para continuar..." _ || true
}

ln_cargar_intenciones() {
    [[ "$LN_INTENTS_LOADED" -eq 1 ]] && return 0

    if [[ ! -f "$LN_ARCHIVO_INTENCIONES" ]]; then
        msg_error "No se encuentra: $LN_ARCHIVO_INTENCIONES"
        return 1
    fi

    ln_invalidar_cache

    local line current_id key val
    current_id=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue

        if [[ "$line" == @* ]]; then
            current_id="${line#@}"
            current_id="${current_id// /}"
            LN_META_PRIORITY["$current_id"]="${LN_META_PRIORITY[$current_id]:-100}"
            continue
        fi

        [[ -z "$current_id" ]] && continue

        key="${line%%=*}"
        val="${line#*=}"
        key="${key// /}"

        case "$key" in
            priority)
                LN_META_PRIORITY["$current_id"]="$val"
                ;;
            label)
                LN_META_LABEL["$current_id"]="$val"
                ;;
            command)
                LN_META_CMD["$current_id"]="$val"
                ;;
            pattern)
                val="$(ln_normalize "$val")"
                if [[ -n "${LN_PATRONES[$current_id]:-}" ]]; then
                    LN_PATRONES["$current_id"]="${LN_PATRONES[$current_id]}|${val}"
                else
                    LN_PATRONES["$current_id"]="$val"
                fi
                ;;
        esac
    done < "$LN_ARCHIVO_INTENCIONES"

    local id prio
    for id in "${!LN_META_PRIORITY[@]}"; do
        prio="${LN_META_PRIORITY[$id]:-999}"
        LN_INTENT_ORDER+=("${prio}|${id}")
    done

    IFS=$'\n' LN_INTENT_ORDER=($(sort -t'|' -k1,1n <<< "${LN_INTENT_ORDER[*]}"))
    unset IFS

    local sorted=() entry
    for entry in "${LN_INTENT_ORDER[@]}"; do
        sorted+=("${entry#*|}")
    done
    LN_INTENT_ORDER=("${sorted[@]}")
    LN_INTENTS_LOADED=1
    return 0
}

ln_detectar_intencion() {
    local input
    input="$(ln_normalize "$1")"

    case "$input" in
        salir|exit|volver|0) echo "QUIT"; return ;;
        ayuda|help|ejemplos) echo "HELP"; return ;;
        documentacion|documentación|docs|doc) echo "DOCS"; return ;;
    esac

    ln_cargar_intenciones || { echo "UNKNOWN"; return; }

    local id pat IFS='|'
    for id in "${LN_INTENT_ORDER[@]}"; do
        [[ -n "${LN_PATRONES[$id]:-}" ]] || continue
        for pat in ${LN_PATRONES[$id]}; do
            [[ -n "$pat" ]] || continue
            if [[ "$input" == *"$pat"* ]]; then
                echo "$id"
                return
            fi
        done
    done

    echo "UNKNOWN"
}

ln_etiqueta_intencion() {
    local id="$1"
    echo "${LN_META_LABEL[$id]:-$id}"
}

ln_comando_intencion() {
    local id="$1"
    echo "${LN_META_CMD[$id]:-}"
}

ln_extraer_contenedor() {
    local input="$1" c=""
    if [[ "$input" =~ (contenedor|container)[[:space:]]+([^[:space:]]+) ]]; then
        c="${BASH_REMATCH[2]}"
    elif [[ "$input" =~ (contenedor|container)[[:space:]]*\"([^\"]+)\" ]]; then
        c="${BASH_REMATCH[2]}"
    fi
    if [[ -z "$c" ]]; then
        [[ "$input" == *" web"* || "$input" == web* ]] && c="web"
        [[ "$input" == *" api"* || "$input" == api* ]] && c="api"
    fi
    echo "$c"
}

ln_extraer_puerto() {
    local input="$1" port=""
    [[ "$input" =~ ([0-9]{2,5}) ]] && port="${BASH_REMATCH[1]}"
    echo "$port"
}

ln_extraer_pista_imagen() {
    local input="$1"
    if [[ "$input" == *nginx* ]]; then
        echo "nginx:alpine"
        return
    fi
    if [[ "$input" =~ ([a-z0-9._-]+/[a-z0-9._-]+:[a-z0-9._-]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return
    fi
    if [[ "$input" =~ ([a-z0-9._-]+:[a-z0-9._-]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return
    fi
    echo ""
}

ln_contenedor_o_pedir() {
    local running_only="${1:-false}"
    local c
    c="$(ln_extraer_contenedor "${LN_INPUT:-}")"
    if [[ -n "$c" ]]; then
        echo "$c"
        return 0
    fi
    pedir_contenedor "$running_only"
}

ln_resolver_dir_compose() {
    local active
    active="$(qw_obtener_proyecto_activo 2>/dev/null || true)"
    if [[ -n "$active" ]] && qw_proyecto_tiene_compose "$active" 2>/dev/null; then
        if pedir_si_no "¿Usar proyecto activo ($active)?" "s"; then
            echo "$active"
            return 0
        fi
    fi
    pedir_carpeta_compose
}

ln_mostrar_resumen_intencion() {
    local intent="$1"
    echo
    echo -e "🐋 He entendido: ${C_BOLD}$(ln_etiqueta_intencion "$intent")${C_RESET}"
    echo "   Comando equivalente: $(ln_comando_intencion "$intent")"
    echo
}

ln_pedir_y_ejecutar() {
    local fn="$1"
    if pedir_si_no "¿Ejecutarlo ahora?" "s"; then
        echo
        "$fn"
    fi
}

# --- Acciones ---

ln_accion_list_running() { verificar_docker && docker ps; }
ln_accion_list_all() { verificar_docker && docker ps -a; }
ln_accion_list_prompt() { verificar_docker && docker ps -a; }

ln_accion_logs() {
    verificar_docker || return
    local c; c="$(ln_contenedor_o_pedir true)" || return
    docker logs --tail=200 "$c"
}

ln_accion_logs_follow() {
    verificar_docker || return
    local c; c="$(ln_contenedor_o_pedir true)" || return
    docker logs --tail=50 -f "$c"
}

ln_accion_exec() {
    verificar_docker || return
    local c shell="${2:-sh}"
    c="$(ln_contenedor_o_pedir true)" || return
    read -r -p "Shell [$shell]: " s
    s="${s:-$shell}"
    docker exec -it "$c" "$s"
}

ln_accion_stop() {
    verificar_docker || return
    local c; c="$(ln_contenedor_o_pedir false)" || return
    docker stop "$c"
}

ln_accion_stop_force() {
    verificar_docker || return
    local c; c="$(ln_contenedor_o_pedir false)" || return
    docker stop -t 0 "$c"
}

ln_accion_start() {
    verificar_docker || return
    local c; c="$(ln_contenedor_o_pedir false)" || return
    docker start "$c"
}

ln_accion_restart() {
    verificar_docker || return
    local c; c="$(ln_contenedor_o_pedir false)" || return
    docker restart "$c"
}

ln_accion_image_pull() {
    verificar_docker || return
    local img; img="$(ln_extraer_pista_imagen "${LN_INPUT:-}")"
    read -r -p "Imagen a descargar [${img:-nginx:alpine}]: " img
    img="${img:-nginx:alpine}"
    docker pull "$img"
}

ln_accion_image_list() { verificar_docker && docker images; }

ln_accion_image_rmi() {
    verificar_docker || return
    local img; img="$(pedir_imagen)" || return
    docker rmi "$img"
}

ln_accion_image_rmi_force() {
    verificar_docker || return
    local img; img="$(pedir_imagen)" || return
    docker rmi -f "$img"
}

ln_accion_image_tag() {
    verificar_docker || return
    local old new
    old="$(pedir_imagen)" || return
    read -r -p "Nueva etiqueta: " new
    [[ -n "$new" ]] || return
    docker tag "$old" "$new"
    msg_ok "Etiquetada: $old -> $new"
}

ln_accion_image_build() {
    verificar_docker || return
    local dir tag
    read -r -p "Directorio [.]: " dir
    dir="${dir:-.}"
    dir="$(qw_expandir_ruta "$dir")"
    read -r -p "Etiqueta (ej: miapp:1.0): " tag
    [[ -n "$tag" ]] || return
    docker build -t "$tag" "$dir"
}

ln_accion_compose_up() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    (cd "$dir" && docker compose up -d)
}

ln_accion_compose_up_fg() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    (cd "$dir" && docker compose up)
}

ln_accion_compose_up_build() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    (cd "$dir" && docker compose up -d --build)
}

ln_accion_compose_down() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    (cd "$dir" && docker compose down)
}

ln_accion_compose_down_v() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    (cd "$dir" && docker compose down -v)
}

ln_accion_compose_ps() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    (cd "$dir" && docker compose ps)
}

ln_accion_compose_ls() {
    verificar_docker || return
    docker compose ls
}

ln_accion_compose_logs() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    (cd "$dir" && docker compose logs --tail=100)
}

ln_accion_compose_logs_follow() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    (cd "$dir" && docker compose logs -f --tail=100)
}

ln_accion_compose_build() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    (cd "$dir" && docker compose build)
}

ln_accion_port_busy() {
    local port; port="$(ln_extraer_puerto "${LN_INPUT:-}")"
    port="${port:-8080}"
    msg_info "Diagnosticando puerto $port..."
    if existe_comando lsof; then
        sudo lsof -i ":$port" 2>/dev/null || msg_ok "lsof: ningún proceso en :$port"
    elif existe_comando ss; then
        ss -tulpn | grep ":$port " || msg_ok "ss: puerto $port libre"
    else
        msg_aviso "Instala lsof o ss para diagnosticar puertos."
    fi
    echo "Sugerencia: cambia el mapeo (-p ${port}1:80) o HOST_PORT en compose/.env"
}

ln_accion_page_not_visible() {
    verificar_docker || return
    msg_info "Comprobando contenedores..."
    docker ps
    echo
    local active
    active="$(qw_obtener_proyecto_activo 2>/dev/null || true)"
    if [[ -n "$active" ]] && qw_proyecto_tiene_compose "$active" 2>/dev/null; then
        msg_info "Servicios del proyecto activo:"
        (cd "$active" && docker compose ps) || true
        echo
        read -r -p "¿Ver logs del compose? (s/N): " v
        if es_afirmativo "${v:-N}"; then
            (cd "$active" && docker compose logs --tail=50) || true
        fi
    fi
    echo "Revisa: puerto correcto, contenedor Up, firewall, URL http://localhost:PUERTO"
}

ln_accion_prune() {
    verificar_docker || return
    docker system prune -f
}

ln_accion_prune_all() {
    verificar_docker || return
    docker system prune -a -f
}

ln_accion_prune_volumes() {
    verificar_docker || return
    docker system prune -a -f --volumes
}

ln_accion_system_df() { verificar_docker && docker system df; }
ln_accion_container_prune() { verificar_docker && docker container prune -f; }
ln_accion_image_prune() { verificar_docker && docker image prune -a -f; }

ln_accion_troubleshoot() {
    verificar_docker || return
    echo "=== docker ps ==="
    docker ps
    echo
    local active
    active="$(qw_obtener_proyecto_activo 2>/dev/null || true)"
    if [[ -n "$active" ]] && qw_proyecto_tiene_compose "$active" 2>/dev/null; then
        echo "=== compose ps ($active) ==="
        (cd "$active" && docker compose ps) || true
    fi
    echo
    echo "Sugerencias: docker logs <contenedor> | compose logs | revisar puerto | compose down -v && up --build"
}

ln_accion_reset_project() {
    verificar_docker || return
    local dir; dir="$(ln_resolver_dir_compose)" || return
    msg_aviso "Esto eliminará volúmenes del proyecto en: $dir"
    pedir_si_no "¿Continuar con down -v + up --build?" "s" || return
    (cd "$dir" && docker compose down -v && docker compose up -d --build)
}

ln_accion_concepts() { op_module_conceptos_esenciales; }
ln_accion_practice_nginx() { op_module_practica_dockerfile_web; }
ln_accion_practice_auto() { op_module_practica_dockerfile_web; }

ln_accion_portability_bonus() {
    cat << 'EOF'

🐋 Bonus didáctico — «En mi máquina funciona»

Eso es precisamente lo que Docker intenta evitar: empaquetar la app + dependencias
en una imagen para que funcione igual en otro equipo, otro SO o en el servidor.

Prueba: comparte la imagen (docker push) o el proyecto (Dockerfile + compose)
y ejecútalo en otra máquina con los mismos comandos.

EOF
}

ln_mostrar_ejemplos() {
    mostrar_banner
    echo -e "${C_BOLD}Documentacion — ejemplos de frases${C_RESET}"
    echo -e "${C_DIM}  $LN_ARCHIVO_EJEMPLOS${C_RESET}"
    echo
    if [[ -f "$LN_ARCHIVO_EJEMPLOS" ]]; then
        if existe_comando less && [[ -t 0 ]]; then
            less -R "$LN_ARCHIVO_EJEMPLOS" || { cat "$LN_ARCHIVO_EJEMPLOS"; ln_pause; }
        else
            cat "$LN_ARCHIVO_EJEMPLOS"
            ln_pause
        fi
    else
        msg_error "No existe $LN_ARCHIVO_EJEMPLOS"
        msg_info "Crea el archivo o revisa la instalacion en: $LN_DIR_CONFIG"
        ln_pause
    fi
}

ln_editar_intenciones() {
    mostrar_banner
    msg_info "Tras guardar, las frases se recargan automaticamente."
    qw_editar_archivo "$LN_ARCHIVO_INTENCIONES"
    ln_invalidar_cache
    ln_cargar_intenciones || true
    ln_pause
}

ln_editar_ejemplos() {
    mostrar_banner
    qw_editar_archivo "$LN_ARCHIVO_EJEMPLOS"
    ln_pause
}

ln_mostrar_ayuda_resumida() {
    echo "Escribe una frase o consulta la documentación completa (opción 2 del menú)."
    echo
    if [[ -f "$LN_ARCHIVO_EJEMPLOS" ]]; then
        echo "Vista rápida (primeras líneas de ejemplos.md):"
        head -n 35 "$LN_ARCHIVO_EJEMPLOS"
        echo
        echo "... (ver documentación completa en el menú)"
    fi
}

ln_ejecutar_intencion() {
    local intent="$1"
    local input="$2"
    LN_INPUT="$input"

    case "$intent" in
        LIST_RUNNING)     ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_list_running ;;
        LIST_ALL)         ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_list_all ;;
        LIST_CONTAINERS_PROMPT) ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_list_prompt ;;
        LOGS)             ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_logs ;;
        LOGS_FOLLOW)      ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_logs_follow ;;
        EXEC)             ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_exec ;;
        STOP)             ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_stop ;;
        STOP_FORCE)       ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_stop_force ;;
        START)            ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_start ;;
        RESTART)          ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_restart ;;
        IMAGE_PULL)       ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_image_pull ;;
        IMAGE_LIST)       ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_image_list ;;
        IMAGE_RMI)        ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_image_rmi ;;
        IMAGE_RMI_FORCE)  ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_image_rmi_force ;;
        IMAGE_TAG)        ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_image_tag ;;
        IMAGE_BUILD)      ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_image_build ;;
        COMPOSE_UP)       ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_up ;;
        COMPOSE_UP_FG)    ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_up_fg ;;
        COMPOSE_UP_BUILD) ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_up_build ;;
        COMPOSE_DOWN)     ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_down ;;
        COMPOSE_DOWN_V)   ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_down_v ;;
        COMPOSE_PS)       ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_ps ;;
        COMPOSE_LS)       ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_ls ;;
        COMPOSE_LOGS)     ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_logs ;;
        COMPOSE_LOGS_FOLLOW) ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_logs_follow ;;
        COMPOSE_BUILD)    ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_compose_build ;;
        PORT_BUSY)        ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_port_busy ;;
        PAGE_NOT_VISIBLE) ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_page_not_visible ;;
        PRUNE)            ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_prune ;;
        PRUNE_ALL)        ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_prune_all ;;
        PRUNE_VOLUMES)    ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_prune_volumes ;;
        SYSTEM_DF)        ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_system_df ;;
        CONTAINER_PRUNE)  ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_container_prune ;;
        IMAGE_PRUNE)      ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_image_prune ;;
        TROUBLESHOOT)     ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_troubleshoot ;;
        RESET_PROJECT)    ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_reset_project ;;
        CONCEPTS)         ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_concepts ;;
        PRACTICA_NGINX|PRACTICE_AUTO) ln_mostrar_resumen_intencion "$intent"; ln_pedir_y_ejecutar ln_accion_practice_nginx ;;
        PORTABILITY_BONUS) ln_mostrar_resumen_intencion "$intent"; ln_accion_portability_bonus ;;
        DOCS)             ln_mostrar_ejemplos ;;
        HELP|UNKNOWN)
            echo "🐋 No entendí exactamente qué quieres hacer."
            ln_mostrar_ayuda_resumida
            ;;
    esac
}

ln_bucle_interactivo() {
    while true; do
        mostrar_banner
        echo -e "${C_BOLD}Modo lenguaje natural${C_RESET}"
        echo
        echo "QuickWhale entiende lo que necesitas. Escribe con tus palabras:"
        echo
        echo -e "${C_DIM}  Frases configurables en: ${LN_ARCHIVO_INTENCIONES}${C_RESET}"
        echo "(salir | ayuda | documentacion)"
        echo
        read -r -p "> " user_input

        user_input="$(ln_normalize "$user_input")"
        [[ -n "$user_input" ]] || continue

        local intent
        intent="$(ln_detectar_intencion "$user_input")"

        [[ "$intent" == "QUIT" ]] && return

        ln_ejecutar_intencion "$intent" "$user_input"

        echo
        read -r -p "¿Quieres ayuda con algo más? (s/N): " again
        again="${again:-N}"
        es_afirmativo "$again" || return
    done
}

menu_lenguaje_natural() {
    while true; do
        mostrar_banner
        echo -e "${C_BOLD}Modo lenguaje natural${C_RESET}"
        echo
        echo "   1) Escribir lo que quiero hacer"
        echo "   2) Ver ejemplos de frases (ejemplos.md)"
        echo "   3) Editar frases reconocidas (intenciones.conf)"
        echo "   4) Editar ejemplos (ejemplos.md)"
        echo
        echo "   0) Volver"
        echo
        read -r -p "Selecciona una opción: " choice
        case "$choice" in
            1) ln_bucle_interactivo ;;
            2) ln_mostrar_ejemplos ;;
            3) ln_editar_intenciones ;;
            4) ln_editar_ejemplos ;;
            0) return ;;
            *) msg_error "Opcion no valida."; ln_pause ;;
        esac
    done
}
