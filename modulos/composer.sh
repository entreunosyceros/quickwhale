op_composer_install() {
    mostrar_banner
    if ! existe_comando composer; then
        msg_error "Composer no está instalado."
        pausa
        return
    fi
    local dir
    read -r -p "Directorio del proyecto [$PWD]: " dir
    dir="${dir:-$PWD}"
    dir="$(qw_expandir_ruta "$dir")"
    if [[ ! -f "$dir/composer.json" ]]; then
        msg_aviso "No hay composer.json en '$dir'."
    fi
    read -r -p "¿Modo producción (--no-dev)? (s/N): " prod
    if [[ "${prod,,}" == "s" ]]; then
        (cd "$dir" && composer install --no-dev --optimize-autoloader)
    else
        (cd "$dir" && composer install)
    fi
    msg_ok "composer install completado."
    pausa
}

op_composer_update() {
    mostrar_banner
    if ! existe_comando composer; then
        msg_error "Composer no está instalado."
        pausa
        return
    fi
    local dir
    read -r -p "Directorio del proyecto [$PWD]: " dir
    dir="${dir:-$PWD}"
    dir="$(qw_expandir_ruta "$dir")"
    (cd "$dir" && composer update)
    msg_ok "composer update completado."
    pausa
}

op_composer_custom() {
    mostrar_banner
    if ! existe_comando composer; then
        msg_error "Composer no está instalado."
        return 1
    fi
    local dir cmd
    read -r -p "Directorio [$PWD]: " dir
    dir="${dir:-$PWD}"
    dir="$(qw_expandir_ruta "$dir")"
    read -r -p "Comando (ej: require monolog/monolog): " cmd
    if [[ -z "$cmd" ]]; then
        msg_error "Comando vacío."
        return 1
    fi
    (cd "$dir" && composer $cmd)
}
