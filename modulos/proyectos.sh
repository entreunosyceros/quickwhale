# Mis proyectos: contenedores propios, plantillas YAML/HTML y edición de archivos

qw_asegurar_dir_proyectos() {
    mkdir -p "$DIR_PROYECTOS"
    mkdir -p "$(dirname "$QW_ARCHIVO_ESTADO")"
}

qw_obtener_proyecto_activo() {
    qw_asegurar_dir_proyectos
    if [[ -f "$QW_ARCHIVO_ESTADO" ]]; then
        # shellcheck source=/dev/null
        source "$QW_ARCHIVO_ESTADO" 2>/dev/null || true
    fi
    echo "${ACTIVE_PROJECT:-}"
}

qw_establecer_proyecto_activo() {
    local dir="$1"
    qw_asegurar_dir_proyectos
    {
        echo "# QuickWhale - proyecto activo"
        printf 'ACTIVE_PROJECT=%q\n' "$dir"
    } > "$QW_ARCHIVO_ESTADO"
    msg_ok "Proyecto activo: $dir"
}

qw_proyecto_tiene_compose() {
    local dir="$1"
    [[ -f "$dir/compose.yaml" || -f "$dir/compose.yml" \
        || -f "$dir/docker-compose.yaml" || -f "$dir/docker-compose.yml" ]]
}

qw_buscar_archivos_yaml() {
    local dir="$1"
    find "$dir" -maxdepth 3 -type f \( \
        -name '*.yml' -o -name '*.yaml' \
    \) ! -path '*/.*' 2>/dev/null | sort
}

qw_buscar_archivos_html() {
    local dir="$1"
    find "$dir" -maxdepth 4 -type f -name '*.html' ! -path '*/.*' 2>/dev/null | sort
}

qw_pedir_dir_proyecto() {
    local active default
    active="$(qw_obtener_proyecto_activo)"
    default="${active:-$DIR_PROYECTOS}"

    echo
    msg_info "Proyecto activo: ${active:-ninguno}"
    msg_info "Carpeta de proyectos: $DIR_PROYECTOS"
    echo
    read -r -p "Ruta del proyecto [$default]: " dir
    dir="${dir:-$default}"
    dir="$(qw_expandir_ruta "$dir")"

    if [[ ! -d "$dir" ]]; then
        msg_error "No existe el directorio: $dir"
        return 1
    fi
    echo "$dir"
}

qw_listar_plantillas_compose() {
    local f
    PLANTILLAS_COMPOSE=()
    shopt -s nullglob
    for f in "${DIR_PLANTILLAS}/compose/"*.yaml "${DIR_PLANTILLAS}/compose/"*.yml; do
        PLANTILLAS_COMPOSE+=("$(basename "$f")")
    done
    shopt -u nullglob
}

qw_listar_plantillas_html() {
    local f
    PLANTILLAS_HTML=()
    shopt -s nullglob
    for f in "${DIR_PLANTILLAS}/html/"*.html; do
        PLANTILLAS_HTML+=("$(basename "$f")")
    done
    shopt -u nullglob
}

op_proyectos_listar_y_seleccionar() {
    mostrar_banner
    qw_asegurar_dir_proyectos

    echo -e "${C_BOLD}Mis proyectos${C_RESET} ${C_DIM}($DIR_PROYECTOS)${C_RESET}"
    echo

    local dirs=() name
    shopt -s nullglob
    for name in "$DIR_PROYECTOS"/*; do
        [[ -d "$name" ]] && dirs+=("$name")
    done
    shopt -u nullglob

    if [[ ${#dirs[@]} -eq 0 ]]; then
        msg_aviso "Aún no hay proyectos. Crea uno desde plantilla (opción 2)."
        pausa
        return 0
    fi

    local i
    for i in "${!dirs[@]}"; do
        local mark=""
        [[ "$(qw_obtener_proyecto_activo)" == "${dirs[$i]}" ]] && mark=" ${C_GREEN}(activo)${C_RESET}"
        echo "  $((i + 1))) $(basename "${dirs[$i]}") -> ${dirs[$i]}${mark}"
    done
    echo "  0) Solo ver, sin cambiar activo"
    echo
    read -r -p "Selecciona proyecto activo: " choice

    if [[ "$choice" == "0" || -z "$choice" ]]; then
        pausa
        return 0
    fi

    [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#dirs[@]} )) || {
        msg_error "Opción inválida."
        pausa
        return 1
    }

    qw_establecer_proyecto_activo "${dirs[$((choice - 1))]}"
    pausa
}

op_proyecto_crear_desde_plantilla() {
    mostrar_banner
    qw_asegurar_dir_proyectos

    local name nombre tpl_html tpl_compose dest
    read -r -p "Nombre del proyecto (carpeta): " name
    [[ -n "$name" ]] || { msg_error "Nombre obligatorio."; pausa; return 1; }
    name="${name// /-}"

    dest="${DIR_PROYECTOS}/${name}"
    if [[ -e "$dest" ]]; then
        msg_error "Ya existe: $dest"
        pausa
        return 1
    fi

    read -r -p "Tu nombre (para HTML) [opcional]: " nombre
    nombre="${nombre:-}"

    qw_listar_plantillas_compose
    qw_elegir_de_lista "Plantilla Compose (YAML)" PLANTILLAS_COMPOSE || { pausa; return 1; }
    tpl_compose="$QW_RESULTADO_ELECCION"

    qw_listar_plantillas_html
    qw_elegir_de_lista "Plantilla HTML" PLANTILLAS_HTML || { pausa; return 1; }
    tpl_html="$QW_RESULTADO_ELECCION"

    mkdir -p "${dest}/html"

    cp "${DIR_PLANTILLAS}/compose/${tpl_compose}" "${dest}/compose.yaml"
    cp "${DIR_PLANTILLAS}/html/${tpl_html}" "${dest}/html/index.html"

    if [[ -f "${DIR_PLANTILLAS}/dockerfile/nginx-estatico.Dockerfile" ]] \
        && grep -q 'build: \.' "${dest}/compose.yaml" 2>/dev/null; then
        cp "${DIR_PLANTILLAS}/dockerfile/nginx-estatico.Dockerfile" "${dest}/Dockerfile"
    fi

    if [[ "$tpl_compose" == node-postgres* ]]; then
        mkdir -p "${dest}/app"
        cat > "${dest}/app/package.json" <<'PKG'
{
  "name": "mi-api",
  "version": "1.0.0",
  "scripts": { "dev": "node server.js" }
}
PKG
        cat > "${dest}/app/server.js" <<'JS'
const http = require("http");
http.createServer((req, res) => {
  res.end("Hola desde Node en Docker\n");
}).listen(3000, () => console.log("API en :3000"));
JS
    fi

    local nombre_escapado
    nombre_escapado="$(printf '%s' "$nombre" | sed 's/[&/\|]/\\&/g')"
    sed -i "s|{{NOMBRE}}|${nombre_escapado}|g" "${dest}/html/index.html" 2>/dev/null || true

    cat > "${dest}/.env" <<EOF
PROJECT_NAME=${name}
HOST_PORT=8080
EOF

    qw_establecer_proyecto_activo "$dest"
    msg_ok "Proyecto creado: $dest"
    msg_info "Archivos: compose.yaml, html/index.html"
    [[ -f "${dest}/Dockerfile" ]] && msg_info "También: Dockerfile"
    pausa
}

op_proyecto_registrar_externo() {
    mostrar_banner
    local dir
    dir=$(qw_pedir_dir_proyecto) || { pausa; return 1; }
    qw_establecer_proyecto_activo "$dir"
    msg_info "Puedes usar Compose y editar YAML/HTML sobre esta carpeta."
    pausa
}

op_proyecto_editar_yaml() {
    mostrar_banner
    local dir files=() f
    dir=$(qw_pedir_dir_proyecto) || { pausa; return 1; }

    mapfile -t files < <(qw_buscar_archivos_yaml "$dir")
    if [[ ${#files[@]} -eq 0 ]]; then
        msg_aviso "No hay archivos .yml/.yaml en $dir"
        read -r -p "¿Crear compose.yaml vacío desde plantilla stack-vacio? (s/N): " c
        if [[ "${c,,}" == "s" ]]; then
            cp "${DIR_PLANTILLAS}/compose/stack-vacio.compose.yaml" "${dir}/compose.yaml"
            files=("${dir}/compose.yaml")
        else
            pausa
            return 1
        fi
    fi

    qw_elegir_de_lista "Archivo YAML a editar" files || { pausa; return 1; }
    qw_editar_archivo "$QW_RESULTADO_ELECCION"
    msg_ok "Guardado (si cerraste el editor correctamente)."
    pausa
}

op_proyecto_editar_html() {
    mostrar_banner
    local dir files=()
    dir=$(qw_pedir_dir_proyecto) || { pausa; return 1; }

    mapfile -t files < <(qw_buscar_archivos_html "$dir")
    if [[ ${#files[@]} -eq 0 ]]; then
        msg_aviso "No hay .html en $dir"
        read -r -p "¿Crear html/index.html desde plantilla básica? (s/N): " c
        if [[ "${c,,}" == "s" ]]; then
            mkdir -p "${dir}/html"
            cp "${DIR_PLANTILLAS}/html/index-basico.html" "${dir}/html/index.html"
            files=("${dir}/html/index.html")
        else
            pausa
            return 1
        fi
    fi

    qw_elegir_de_lista "Archivo HTML a editar" files || { pausa; return 1; }
    qw_editar_archivo "$QW_RESULTADO_ELECCION"
    msg_ok "Guardado (si cerraste el editor correctamente)."
    pausa
}

op_proyecto_editar_dockerfile() {
    mostrar_banner
    local dir df
    dir=$(qw_pedir_dir_proyecto) || { pausa; return 1; }
    df="${dir}/Dockerfile"

    if [[ ! -f "$df" ]]; then
        msg_aviso "No hay Dockerfile en $dir"
        read -r -p "¿Copiar plantilla nginx-static? (s/N): " c
        [[ "${c,,}" == "s" ]] || { pausa; return 1; }
        cp "${DIR_PLANTILLAS}/dockerfile/nginx-estatico.Dockerfile" "$df"
    fi

    qw_editar_archivo "$df"
    pausa
}

op_proyecto_editar_plantilla_compose() {
    mostrar_banner
    echo -e "${C_BOLD}Plantillas YAML del sistema${C_RESET}"
    echo -e "${C_DIM}  ${DIR_PLANTILLAS}/compose/${C_RESET}"
    echo

    qw_listar_plantillas_compose
    qw_elegir_de_lista "Plantilla a editar (afecta futuros proyectos)" PLANTILLAS_COMPOSE || {
        pausa
        return 1
    }

    local path="${DIR_PLANTILLAS}/compose/${QW_RESULTADO_ELECCION}"
    msg_aviso "Editar plantillas cambia lo que se copia al crear proyectos nuevos."
    qw_editar_archivo "$path"
    pausa
}

op_proyecto_accion_compose() {
    local action="${1:?acción compose}"
    verificar_docker || return

    mostrar_banner
    local dir
    dir=$(qw_pedir_dir_proyecto) || { pausa; return 1; }

    if ! qw_proyecto_tiene_compose "$dir"; then
        msg_error "No hay compose.yaml/docker-compose.yml en: $dir"
        pausa
        return 1
    fi

    qw_establecer_proyecto_activo "$dir"

    case "$action" in
        up)
            read -r -p "¿Segundo plano (-d)? (S/n): " d
            if [[ "${d,,}" != "n" ]]; then
                (cd "$dir" && docker compose up -d --build)
            else
                (cd "$dir" && docker compose up --build)
            fi
            ;;
        down)
            read -r -p "¿Eliminar volúmenes (-v)? (s/N): " v
            if [[ "${v,,}" == "s" ]]; then
                (cd "$dir" && docker compose down -v)
            else
                (cd "$dir" && docker compose down)
            fi
            ;;
        ps)
            (cd "$dir" && docker compose ps)
            ;;
        logs)
            read -r -p "¿Seguir logs (-f)? (s/N): " f
            if [[ "${f,,}" == "s" ]]; then
                (cd "$dir" && docker compose logs -f --tail=80)
            else
                (cd "$dir" && docker compose logs --tail=80)
            fi
            ;;
        build)
            (cd "$dir" && docker compose build)
            ;;
        *)
            msg_error "Acción desconocida: $action"
            return 1
            ;;
    esac

    msg_ok "docker compose $action en $dir"
    pausa
}

op_proyecto_aviso_contenedores() {
    mostrar_banner
    echo -e "${C_BOLD}Tus contenedores (sistema completo)${C_RESET}"
    echo
    echo "QuickWhale puede gestionar cualquier contenedor del equipo."
    echo "Usa el menú: Operaciones Docker → listar / iniciar / detener / logs / exec."
    echo
    local active
    active="$(qw_obtener_proyecto_activo)"
    if [[ -n "$active" ]] && qw_proyecto_tiene_compose "$active"; then
        msg_info "Contenedores del proyecto activo ($active):"
        verificar_docker && (cd "$active" && docker compose ps) || true
        echo
    fi
    msg_info "Todos los contenedores en ejecución:"
    verificar_docker && docker ps || true
    pausa
}

menu_mis_proyectos() {
    while true; do
        mostrar_banner
        local active
        active="$(qw_obtener_proyecto_activo)"
        echo -e "${C_BOLD}Mis proyectos${C_RESET} ${C_DIM}(contenedores y archivos propios)${C_RESET}"
        echo -e "  Activo: ${C_CYAN}${active:-ninguno}${C_RESET}"
        echo -e "  Carpeta: ${C_DIM}$DIR_PROYECTOS${C_RESET}"
        echo -e "${C_DIM}  Las acciones se abren en ventana nueva.${C_RESET}"
        echo
        echo "   1) Ver / elegir proyecto activo"
        echo "   2) Crear proyecto desde plantilla (YAML + HTML)"
        echo "   3) Registrar carpeta externa como proyecto"
        echo
        echo "  --- Docker Compose (proyecto activo o ruta) ---"
        echo "   4) compose up"
        echo "   5) compose down"
        echo "   6) compose ps"
        echo "   7) compose logs"
        echo "   8) compose build"
        echo
        echo "  --- Editar archivos ---"
        echo "   9) Editar YAML (.yml / .yaml) del proyecto"
        echo "  10) Editar HTML del proyecto"
        echo "  11) Editar Dockerfile"
        echo "  12) Editar plantillas YAML del sistema"
        echo
        echo "  13) Ver contenedores (proyecto + sistema)"
        echo
        echo "   0) Volver"
        echo
        read -r -p "Selecciona una opción: " choice
        case "$choice" in
            1)  qw_launch "Mis proyectos" op_proyectos_listar_y_seleccionar ;;
            2)  qw_launch "Crear proyecto" op_proyecto_crear_desde_plantilla ;;
            3)  qw_launch "Proyecto externo" op_proyecto_registrar_externo ;;
            4)  qw_launch "Compose up" op_proyecto_accion_compose up ;;
            5)  qw_launch "Compose down" op_proyecto_accion_compose down ;;
            6)  qw_launch "Compose ps" op_proyecto_accion_compose ps ;;
            7)  qw_launch "Compose logs" op_proyecto_accion_compose logs ;;
            8)  qw_launch "Compose build" op_proyecto_accion_compose build ;;
            9)  qw_launch "Editar YAML" op_proyecto_editar_yaml ;;
            10) qw_launch "Editar HTML" op_proyecto_editar_html ;;
            11) qw_launch "Editar Dockerfile" op_proyecto_editar_dockerfile ;;
            12) qw_launch "Plantillas YAML" op_proyecto_editar_plantilla_compose ;;
            13) qw_launch "Contenedores" op_proyecto_aviso_contenedores ;;
            0) return ;;
            *) msg_error "Opción no válida."; pausa ;;
        esac
    done
}
