#!/usr/bin/env bash
# =============================================================================
# QuickWhale v1.0 - "Aprendiendo Bash"
# Punto de entrada: carga módulos desde lib/ y modulos/
# =============================================================================

set -euo pipefail

export QUICKWHALE_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# shellcheck source=lib/arranque.sh
source "${QUICKWHALE_ROOT}/lib/arranque.sh"
qw_cargar_todo

main() {
    case "${1:-}" in
        run-activity)
            shift
            qw_run_activity_child "${1:?falta nombre de actividad}"
            exit 0
            ;;
        install|setup)
            verificar_ubuntu
            instalar_todo
            exit 0
            ;;
        status)
            op_docker_status
            exit 0
            ;;
        docker)
            menu_operaciones_docker
            exit 0
            ;;
        link|alias)
            instalar_comando_global
            exit 0
            ;;
        demo|example)
            menu_demo_compose
            exit 0
            ;;
        didactic|modules|apuntes)
            menu_modulos_didacticos
            exit 0
            ;;
        projects|mis-proyectos)
            menu_mis_proyectos
            exit 0
            ;;
        text|natural|lenguaje|lenguaje-natural|natural-language)
            menu_lenguaje_natural
            exit 0
            ;;
        credits|creditos)
            op_show_credits
            exit 0
            ;;
        help|-h|--help)
            echo "Uso: $0 [comando]"
            echo
            echo "Comandos:"
            echo "  (sin args)   Menú interactivo (actividades en ventana nueva)"
            echo "  install      Instalar Docker + Composer + comando global (sudo)"
            echo "  link         Crear enlace /usr/local/bin/quickwhale (sudo)"
            echo "  docker       Menú de operaciones Docker"
            echo "  demo         Proyecto de ejemplo Compose"
            echo "  didactic     Módulos didácticos (apuntes + prácticas)"
            echo "  projects     Mis proyectos (YAML/HTML, plantillas, compose)"
            echo "  text         Modo lenguaje natural"
            echo "  credits      Créditos y enlace al repositorio"
            echo "  status       Estado de Docker y Composer"
            echo "  help         Esta ayuda"
            echo
            echo "Estructura:"
            echo "  ${QUICKWHALE_ROOT}/lib/         utilidades, terminal, editor"
            echo "  ${QUICKWHALE_ROOT}/modulos/    instalación, docker, proyectos..."
            echo "  ${QUICKWHALE_ROOT}/plantillas/  plantillas YAML/HTML"
            echo "  ${QUICKWHALE_ROOT}/ejemplos/   demos de ejemplo"
            echo "  ~/.quickwhale/projects/       tus proyectos personales"
            exit 0
            ;;
        "")
            menu_principal
            ;;
        *)
            msg_error "Comando desconocido: $1"
            msg_info "Usa: $0 help"
            exit 1
            ;;
    esac
}

main "$@"
