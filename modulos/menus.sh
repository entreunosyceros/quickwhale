# Menús interactivos (el menú permanece; las acciones se lanzan en ventana nueva)

menu_operaciones_docker() {
    while true; do
        mostrar_banner
        echo -e "${C_BOLD}Operaciones Docker${C_RESET}"
        echo -e "${C_DIM}  Gestiona todos los contenedores e imagenes del equipo.${C_RESET}"
        echo -e "${C_DIM}  Cada operación se abre en ventana nueva.${C_RESET}"
        echo
        echo "  --- Contenedores ---"
        echo "   1) Listar contenedores"
        echo "   2) Iniciar contenedor"
        echo "   3) Detener contenedor"
        echo "   4) Reiniciar contenedor"
        echo "   5) Ver logs"
        echo "   6) Entrar al contenedor (exec)"
        echo "   7) Ejecutar nuevo contenedor (run)"
        echo "   8) Eliminar contenedor"
        echo
        echo "  --- Imágenes ---"
        echo "   9) Listar imágenes"
        echo "  10) Descargar imagen (pull)"
        echo "  11) Construir imagen (build)"
        echo "  12) Eliminar imagen"
        echo
        echo "  --- Docker Compose ---"
        echo "  13) compose up"
        echo "  14) compose down"
        echo "  15) compose ps"
        echo "  16) compose logs"
        echo
        echo "  --- Mantenimiento ---"
        echo "  17) Limpiar sistema (prune)"
        echo
        echo "   0) Volver al menú principal"
        echo
        read -r -p "Selecciona una opción: " choice
        case "$choice" in
            1)  qw_launch "Listar contenedores" op_list_containers ;;
            2)  qw_launch "Iniciar contenedor" op_start_container ;;
            3)  qw_launch "Detener contenedor" op_stop_container ;;
            4)  qw_launch "Reiniciar contenedor" op_restart_container ;;
            5)  qw_launch "Logs contenedor" op_logs_container ;;
            6)  qw_launch "Exec contenedor" op_exec_container ;;
            7)  qw_launch "Run contenedor" op_run_container ;;
            8)  qw_launch "Eliminar contenedor" op_remove_container ;;
            9)  qw_launch "Listar imágenes" op_list_images ;;
            10) qw_launch "Pull imagen" op_pull_image ;;
            11) qw_launch "Build imagen" op_build_image ;;
            12) qw_launch "Eliminar imagen" op_remove_image ;;
            13) qw_launch "Compose up" op_compose_up ;;
            14) qw_launch "Compose down" op_compose_down ;;
            15) qw_launch "Compose ps" op_compose_ps ;;
            16) qw_launch "Compose logs" op_compose_logs ;;
            17) qw_launch "System prune" op_system_prune ;;
            0)  return ;;
            *)  msg_error "Opción no válida."; pausa ;;
        esac
    done
}

menu_operaciones_composer() {
    while true; do
        mostrar_banner
        echo -e "${C_BOLD}Operaciones Composer${C_RESET}"
        echo -e "${C_DIM}  Cada operación se abre en ventana nueva.${C_RESET}"
        echo
        echo "   1) composer install"
        echo "   2) composer update"
        echo "   3) Ejecutar comando personalizado"
        echo
        echo "   0) Volver"
        echo
        read -r -p "Selecciona una opción: " choice
        case "$choice" in
            1) qw_launch "Composer install" op_composer_install ;;
            2) qw_launch "Composer update" op_composer_update ;;
            3) qw_launch "Composer custom" op_composer_custom ;;
            0) return ;;
            *) msg_error "Opción no válida."; pausa ;;
        esac
    done
}

menu_instalacion() {
    while true; do
        mostrar_banner
        echo -e "${C_BOLD}Instalación${C_RESET} ${C_DIM}(requiere sudo)${C_RESET}"
        echo -e "${C_DIM}  Se ejecuta en esta terminal (no en ventana nueva).${C_RESET}"
        echo -e "${C_DIM}  Si no eres root: sudo ${SCRIPT_PATH}${C_RESET}"
        echo
        echo "   1) Instalar Docker"
        echo "   2) Instalar Composer"
        echo "   3) Instalar todo (Docker + Composer + comando global)"
        echo "   4) Instalar comando global quickwhale (sudo)"
        echo "   5) Instalar emulador de terminal (ventanas nuevas)"
        echo
        echo "   0) Volver"
        echo
        read -r -p "Selecciona una opción: " choice
        case "$choice" in
            1) instalar_docker; pausa ;;
            2) instalar_composer; pausa ;;
            3) instalar_todo ;;
            4) instalar_comando_global; pausa ;;
            5) instalar_emulador_terminal; pausa ;;
            0) return ;;
            *) msg_error "Opción no válida."; pausa ;;
        esac
    done
}

op_show_credits() {
    mostrar_banner
    echo -e "${C_BOLD}Créditos — ${SCRIPT_NAME} v${VERSION}${C_RESET}"
    echo -e "${C_DIM}  «Aprendiendo Bash»${C_RESET}"
    echo
    cat << 'EOF'
QuickWhale es un asistente interactivo en Bash para el aprendizaje y la
gestión de Docker en Ubuntu. Permite:

  • Instalar Docker Engine y Composer de forma guiada.
  • Ejecutar operaciones Docker habituales sin memorizar la CLI completa.
  • Seguir módulos didácticos (conceptos, prácticas, Compose, apuntes).
  • Crear proyectos personales desde plantillas YAML/HTML y editarlas.
  • Abrir cada actividad en una ventana nueva manteniendo el menú visible.

Proyecto de código abierto. Documentación en README.md del repositorio.
EOF
    echo
    echo -e "${C_BOLD}Repositorio en GitHub:${C_RESET}"
    echo -n "  "
    qw_mostrar_url_clicable "$QW_REPO_URL" "$QW_REPO_URL"
    echo
    echo -e "${C_DIM}  (Ctrl+clic o clic en el enlace si tu terminal lo admite)${C_RESET}"
    echo

    if pedir_si_no "¿Abrir el repositorio en el navegador?" "s"; then
        if qw_abrir_url "$QW_REPO_URL"; then
            msg_ok "Abriendo navegador..."
        fi
    else
        msg_info "URL: $QW_REPO_URL"
    fi
    pausa
}

menu_principal() {
    while true; do
        mostrar_banner
        echo -e "${C_BOLD}Menú principal${C_RESET}"
        echo -e "${C_DIM}  Las actividades se abren en ventana nueva; este menú permanece visible.${C_RESET}"
        echo
        echo "   1) Instalar Docker y/o Composer"
        echo "   2) Operaciones Docker (asistente)"
        echo "   3) Operaciones Composer"
        echo "   4) Estado y servicios (Docker / Composer)"
        echo "   5) Proyecto de ejemplo Docker Compose"
        echo "   6) Modulos didacticos (apuntes)"
        echo "   7) Modo lenguaje natural (¿Qué quieres hacer?)"
        echo "   8) Mis proyectos (plantillas YAML/HTML y contenedores propios)"
        echo "   9) Créditos"
        echo
        echo "   0) Salir"
        echo
        read -r -p "Selecciona una opción: " choice
        case "$choice" in
            1) menu_instalacion ;;
            2) menu_operaciones_docker ;;
            3) menu_operaciones_composer ;;
            4) menu_estado_y_servicios ;;
            5) menu_demo_compose ;;
            6) menu_modulos_didacticos ;;
            7) qw_launch "Modo lenguaje natural" menu_lenguaje_natural ;;
            8) menu_mis_proyectos ;;
            9) op_show_credits ;;
            0)
                echo
                msg_ok "¡Hasta pronto! Gracias por usar ${SCRIPT_NAME}."
                exit 0
                ;;
            *) msg_error "Opción no válida."; pausa ;;
        esac
    done
}
