# Carga ordenada de librerías y módulos

qw_cargar_libreria() {
    local nombre="$1"
    # shellcheck source=/dev/null
    source "${QUICKWHALE_ROOT}/lib/${nombre}.sh"
}

qw_cargar_modulo() {
    local nombre="$1"
    # shellcheck source=/dev/null
    source "${QUICKWHALE_ROOT}/modulos/${nombre}.sh"
}

qw_cargar_todo() {
    qw_cargar_libreria configuracion
    qw_cargar_libreria interfaz
    qw_cargar_libreria utilidades
    qw_cargar_libreria terminal
    qw_cargar_libreria editor

    qw_cargar_modulo instalacion
    qw_cargar_modulo demos
    qw_cargar_modulo docker
    qw_cargar_modulo composer
    qw_cargar_modulo servicios
    qw_cargar_modulo didactica
    qw_cargar_modulo proyectos
    qw_cargar_modulo menus
    qw_cargar_modulo lenguaje_natural
}
