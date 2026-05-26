# UI: banner, colores, mensajes y pausa

mostrar_banner() {
    clear 2>/dev/null || true
    echo -e "${C_CYAN}${C_BOLD}"
    echo ""
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo -e "  ║${C_RESET}${C_BOLD}              ${SCRIPT_NAME} v${VERSION}                         ${C_CYAN}║"
    echo -e "  ║${C_RESET}${C_DIM}              «Aprendiendo Bash»                      ${C_CYAN}║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
    echo -e "${C_DIM}  Instalador Docker + Composer | Asistente de operaciones Docker${C_RESET}"
    echo -e "${C_CYAN}  ─────────────────────────────────────────────────────────────${C_RESET}"
    echo
}

msg_info()    { echo -e "${C_BLUE}[INFO]${C_RESET} $*"; }
msg_ok()      { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
msg_aviso()   { echo -e "${C_YELLOW}[AVISO]${C_RESET} $*"; }
msg_error()   { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }

pausa() {
    if [[ "${QUICKWHALE_CHILD:-}" == "1" ]]; then
        return 0
    fi
    echo
    read -r -p "Pulsa Enter para continuar..." _
}
