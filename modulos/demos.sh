op_example_compose_up() {
    verificar_docker || return
    mostrar_banner

    if [[ ! -f "$DIR_EJEMPLOS/docker-compose.yml" ]]; then
        msg_error "No se encontró el ejemplo en: $DIR_EJEMPLOS"
        pausa
        return 1
    fi

    msg_info "Levantando demo nginx en puerto 8080..."
    (cd "$DIR_EJEMPLOS" && docker compose up -d)
    msg_ok "Demo activa. Abre en el navegador: http://localhost:8080"
    msg_info "Directorio del proyecto: $DIR_EJEMPLOS"
    pausa
}

op_example_compose_ps() {
    verificar_docker || return
    mostrar_banner
    (cd "$DIR_EJEMPLOS" && docker compose ps)
}

op_example_compose_logs_view() {
    verificar_docker || return
    mostrar_banner
    (cd "$DIR_EJEMPLOS" && docker compose logs --tail=50)
}

op_example_compose_down() {
    verificar_docker || return
    mostrar_banner

    if [[ ! -f "$DIR_EJEMPLOS/docker-compose.yml" ]]; then
        msg_error "No se encontró el ejemplo en: $DIR_EJEMPLOS"
        pausa
        return 1
    fi

    (cd "$DIR_EJEMPLOS" && docker compose down)
    msg_ok "Demo detenida."
    pausa
}

menu_demo_compose() {
    while true; do
        mostrar_banner
        echo -e "${C_BOLD}Proyecto de ejemplo Compose${C_RESET}"
        echo -e "${C_DIM}  $DIR_EJEMPLOS${C_RESET}"
        echo
        echo "   1) Levantar demo (nginx en :8080)"
        echo "   2) Detener demo"
        echo "   3) Ver estado (compose ps)"
        echo "   4) Ver logs"
        echo
        echo "   0) Volver"
        echo
        echo -e "${C_DIM}  Las acciones se abren en ventana nueva.${C_RESET}"
        echo
        read -r -p "Selecciona una opción: " choice
        case "$choice" in
            1) qw_launch "Compose up" op_example_compose_up ;;
            2) qw_launch "Compose down" op_example_compose_down ;;
            3) qw_launch "Compose ps" op_example_compose_ps ;;
            4) qw_launch "Compose logs" op_example_compose_logs_view ;;
            0) return ;;
            *) msg_error "Opción no válida."; pausa ;;
        esac
    done
}
