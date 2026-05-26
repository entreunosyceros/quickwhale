# Configuración global de QuickWhale (QUICKWHALE_ROOT lo define quickwhale.sh)

: "${QUICKWHALE_ROOT:?QUICKWHALE_ROOT no definido}"

readonly VERSION="1.0"
readonly SCRIPT_NAME="QuickWhale"
readonly QW_REPO_URL="https://github.com/entreunosyceros/quickwhale"
readonly MIN_UBUNTU_VERSION="20.04"
readonly INSTALL_BIN="/usr/local/bin/quickwhale"

readonly SCRIPT_DIR="${QUICKWHALE_ROOT}"
readonly SCRIPT_PATH="${QUICKWHALE_ROOT}/quickwhale.sh"
readonly DIR_LIBRERIA="${SCRIPT_DIR}/lib"
readonly DIR_MODULOS="${SCRIPT_DIR}/modulos"
readonly DIR_EJEMPLOS="${SCRIPT_DIR}/ejemplos"
readonly DIR_PLANTILLAS="${SCRIPT_DIR}/plantillas"

# Modo lenguaje natural (frases editables sin tocar el código)
readonly LN_DIR_CONFIG="${SCRIPT_DIR}/configuracion/lenguaje_natural"
readonly LN_ARCHIVO_INTENCIONES="${LN_DIR_CONFIG}/intenciones.conf"
readonly LN_ARCHIVO_EJEMPLOS="${LN_DIR_CONFIG}/ejemplos.md"

# Proyectos del usuario (fuera de los ejemplos del repositorio)
readonly QW_HOME_USUARIO="${HOME}/.quickwhale"
readonly DIR_PROYECTOS="${QW_HOME_USUARIO}/projects"
readonly QW_ARCHIVO_ESTADO="${QW_HOME_USUARIO}/state"

readonly DIDACTICA_DIR_EJEMPLO_WEB="${DIR_EJEMPLOS}/web-docker-practica"
readonly DIDACTICA_IMAGEN_WEB_V1="web-docker-practica:1.0"
readonly DIDACTICA_IMAGEN_WEB_V2="web-docker-practica:2.0"
readonly DIDACTICA_CONTENEDOR_WEB_V1="web-practica"
readonly DIDACTICA_CONTENEDOR_WEB_V2="web-practica-v2"

readonly C_RESET='\033[0m'
readonly C_BOLD='\033[1m'
readonly C_DIM='\033[2m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_BLUE='\033[0;34m'
readonly C_CYAN='\033[0;36m'
readonly C_MAGENTA='\033[0;35m'
