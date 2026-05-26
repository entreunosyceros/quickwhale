
pedir_si_no() {
    # $1 texto, $2 defecto (s/N o N/s). Si se pulsa Enter, usa defecto.
    local text="${1:-}"
    local default="${2:-N}"
    local ans
    local suffix
    if [[ "${default^^}" == "S" ]]; then
        suffix="S/n"
    else
        suffix="s/N"
    fi
    read -r -p "$text ($suffix): " ans
    ans="${ans:-$default}"
    if es_afirmativo "$ans"; then
        return 0
    fi
    return 1
}

mostrar_instalacion_por_so() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Instalacion de Docker en macOS, Ubuntu y Windows (apuntes)${C_RESET}"
    echo

    echo -e "${C_BOLD}macOS (recomendado: Docker Desktop)${C_RESET}"
    cat << 'EOF'
Pasos
1) Descargar Docker Desktop para Mac desde la pagina oficial (Apple Silicon o Intel).
2) Abrir el instalador y mover Docker a la carpeta de Aplicaciones.
3) Ejecutar Docker Desktop y aceptar el acuerdo de uso cuando aparezca por primera vez.
4) Esperar a que el servicio quede activo y verificar en Terminal:
   - docker version
   - docker info
   - docker run hello-world
EOF

    echo
    echo -e "${C_BOLD}Ubuntu (dos caminos: Desktop para Linux o Engine nativo)${C_RESET}"
    cat << 'EOF'
Opcion A: Docker Desktop en Ubuntu
1) Configurar primero el repositorio y descargar el paquete .deb.
2) Instalar con apt:
   - sudo apt-get update
   - sudo apt install ./docker-desktop-amd64.deb
3) Iniciar:
   - systemctl --user start docker-desktop

Opcion B: Docker Engine en Ubuntu (especialmente util para formacion tecnica)
1) Repositorio oficial:
   - sudo apt-get update
   - sudo apt-get install ca-certificates curl gnupg
   - sudo mkdir -p /etc/apt/keyrings
   - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   - sudo apt-get update
2) Instalar paquetes:
   - sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
3) Permisos de usuario:
   - sudo usermod -aG docker $USER
4) Cerrar sesion y volver a entrar para aplicar permisos.

Verificacion inicial (muy recomendable al empezar):
- docker version
- docker info
- docker run hello-world
EOF

    echo
    echo -e "${C_BOLD}Windows (recomendado: Docker Desktop + WSL 2 o Hyper-V)${C_RESET}"
    cat << 'EOF'
Pasos
1) Descargar Docker Desktop para Windows desde la pagina oficial.
2) Ejecutar el instalador grafico y seguir el asistente.
3) Usar WSL 2 como backend por defecto cuando sea posible (Docker lo recomienda).
4) Iniciar Docker Desktop desde el menu de inicio y esperar a que el icono quede activo.
5) Verificar desde PowerShell o Terminal:
   - docker version
   - docker info
   - docker run hello-world
EOF

    echo
    pausa
}

op_module_conceptos_esenciales() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Conceptos esenciales (imagen, contenedor, Dockerfile...)${C_RESET}"
    echo
    cat << 'EOF'
Imagen
- Plantilla inmutable con el sistema base, dependencias y aplicacion necesarias para ejecutar un servicio.

Contenedor
- Instancia en ejecucion de una imagen, aislada y gestionable desde la CLI de Docker.

Dockerfile
- Archivo de texto con instrucciones como:
  FROM, COPY, WORKDIR, RUN, CMD, EXPOSE (entre otras).

Registry
- Repositorio remoto para publicar y descargar imagenes (p.ej. Docker Hub).

Volumen
- Mecanismo de persistencia para datos que deben sobrevivir al ciclo de vida del contenedor.

Red
- Capa que permite la comunicacion entre contenedores y con el exterior.

Compose
- Formato declarativo y comando asociado para ejecutar uno o varios servicios de forma reproducible.
EOF
    echo
    pausa
}

op_module_mapa_mental() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Primer mapa mental (flujo basico)${C_RESET}"
    echo
    cat << 'EOF'
1) Descargar una imagen existente con: docker pull  o construir una propia con: docker build
2) Crear y arrancar un contenedor con: docker run
3) Exponer puertos para acceder desde navegador u otras herramientas
4) Revisar funcionamiento con:
   - docker ps
   - docker logs
   - docker exec -it
5) Parar y borrar con:
   - docker stop
   - docker rm
6) Repetir el ciclo despues de modificar el codigo o el Dockerfile
7) Automatizar con Compose cuando haya mas de un servicio o para un arranque reproducible
EOF
    echo
    pausa
}

op_module_catalogo_comandos() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Catalogo de comandos esenciales (por grupos)${C_RESET}"
    echo
    cat << 'EOF'
Comandos generales
  - docker version
  - docker info
  - docker context ls
  - docker help

Imagenes
  - docker images
  - docker pull nginx:alpine
  - docker build -t nombre:tag .
  - docker tag web-clase:1.0 usuario/web-clase:1.0
  - docker push usuario/web-clase:1.0
  - docker rmi web-clase:1.0
  - docker image inspect nginx:alpine

Contenedores
  - docker ps
  - docker ps -a
  - docker run -d --name web -p 8080:80 nginx:alpine
  - docker stop web
  - docker start web
  - docker restart web
  - docker rm web
  - docker logs web
  - docker exec -it web sh
  - docker inspect web
  - docker cp index.html web:/tmp/index.html

Volumenes
  - docker volume ls
  - docker volume create datos-web
  - docker volume inspect datos-web
  - docker volume rm datos-web

Redes
  - docker network ls
  - docker network create red-clase
  - docker network inspect red-clase
  - docker network rm red-clase

Limpieza
  - docker system df
  - docker system prune -a
  - docker container prune
  - docker image prune -a

Compose
  - docker compose up -d
  - docker compose down
  - docker compose ps
  - docker compose logs -f
  - docker compose build
  - docker compose exec web sh
EOF
    echo
    pausa
}

op_module_instrucciones_dockerfile() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Dockerfile: instrucciones clave (tabla rapida)${C_RESET}"
    echo
    cat << 'EOF'
FROM       Imagen base desde la que parte la construccion.
WORKDIR    Carpeta de trabajo dentro de la imagen.
COPY       Copia archivos del host a la imagen.
RUN        Ejecuta comandos durante la construccion.
ENV        Define variables de entorno.
EXPOSE     Documenta el puerto usado por la aplicacion.
CMD        Comando por defecto al arrancar el contenedor.
EOF
    echo
    pausa
}

op_module_buenas_practicas_y_flujo() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Buenas practicas iniciales y flujo de trabajo${C_RESET}"
    echo
    cat << 'EOF'
Buenas practicas iniciales
- Elegir imagenes base oficiales y ligeras cuando sea posible.
- Copiar solo lo necesario al contenedor (build mas rapido y menos superficie de error).
- Reconstruir la imagen cuando cambie la aplicacion (no editar el contenedor).
- Usar Compose para proyectos con varios servicios y arranques reproducibles.

Flujo de trabajo normal en Docker (didactico y realista)
1) Crear carpeta de proyecto con codigo fuente y Dockerfile.
2) Construir imagen etiquetada:
   docker build -t nombre:version .
3) Ejecutar un contenedor:
   docker run -d --name web -p 8080:80 nombre:version
4) Validar desde navegador/terminal/logs.
5) Modificar codigo/config y reconstruir imagen.
6) Parar/eliminar contenedor anterior y levantar la nueva version.
7) Publicar la imagen (docker tag + docker push) si se va a compartir.
8) Sustituir comandos repetitivos por docker compose up cuando el proyecto crezca.
EOF
    echo
    pausa
}

op_module_practica_dockerfile_web() {
    verificar_docker || return
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Practica guiada principal: web estatica con Nginx (Dockerfile + versionado)${C_RESET}"
    echo

    if [[ ! -f "${DIDACTICA_DIR_EJEMPLO_WEB}/Dockerfile" ]]; then
        msg_error "No existe el template de practica en: $DIDACTICA_DIR_EJEMPLO_WEB"
        pausa
        return 1
    fi

    local nombre port1 port2 run_auto exec_shell delete_v1
    read -r -p "Tu nombre [sin espacios problematicos]: " nombre
    nombre="${nombre:-}"

    read -r -p "Puerto host para version 1 (v1) [8080]: " port1
    port1="${port1:-8080}"

    read -r -p "Puerto host para version 2 (v2) [8081]: " port2
    port2="${port2:-8081}"

    if pedir_si_no "Ejecutar automaticamente los comandos (build/run/logs/exec)?" "s"; then
        run_auto=1
    else
        run_auto=0
    fi

    pedir_si_no "Entrar al contenedor con shell interactiva (docker exec -it sh)?" "N" && exec_shell=1 || exec_shell=0
    pedir_si_no "Parar y borrar contenedor v1 al lanzar v2?" "s" && delete_v1=1 || delete_v1=0

    local tmp_workdir workdir idx_name_sed
    tmp_workdir="$(mktemp -d)"
    workdir="${tmp_workdir}/web-docker-practica"
    mkdir -p "$workdir"
    cp -a "${DIDACTICA_DIR_EJEMPLO_WEB}/." "$workdir/"

    idx_name_sed="$(printf '%s' "$nombre" | sed -e 's/[\/&]/\\&/g')"

    # --------------------------
    # Version 1
    # --------------------------
    sed -i "s|{{NOMBRE}}|${idx_name_sed}|g; s|{{VERSION}}|1.0|g; s|<h1>Hola Docker</h1>|<h1>Hola Docker</h1>|g" "${workdir}/index.html" || true

    echo
    echo -e "${C_BOLD}Comandos (v1)${C_RESET}"
    echo "cd \"$workdir\""
    echo "docker build -t ${DIDACTICA_IMAGEN_WEB_V1} ."
    echo "docker run -d --name ${DIDACTICA_CONTENEDOR_WEB_V1} -p ${port1}:80 ${DIDACTICA_IMAGEN_WEB_V1}"
    echo "docker ps"
    echo "docker logs --tail 30 ${DIDACTICA_CONTENEDOR_WEB_V1}"
    if [[ "$exec_shell" -eq 1 ]]; then
        echo "docker exec -it ${DIDACTICA_CONTENEDOR_WEB_V1} sh"
    fi

    if [[ "$run_auto" -eq 1 ]]; then
        docker rm -f "${DIDACTICA_CONTENEDOR_WEB_V1}" >/dev/null 2>&1 || true
        (cd "$workdir" && docker build -t "${DIDACTICA_IMAGEN_WEB_V1}" .)
        docker run -d --name "${DIDACTICA_CONTENEDOR_WEB_V1}" -p "${port1}:80" "${DIDACTICA_IMAGEN_WEB_V1}" >/dev/null
        docker ps
        docker logs --tail 30 "${DIDACTICA_CONTENEDOR_WEB_V1}" || true
        if [[ "$exec_shell" -eq 1 ]]; then
            docker exec -it "${DIDACTICA_CONTENEDOR_WEB_V1}" sh
        fi
        echo -e "${C_GREEN}Acceso recomendado: http://localhost:${port1}${C_RESET}"
    else
        msg_aviso "Ejecucion automatica desactivada para v1."
    fi

    # --------------------------
    # Version 2
    # --------------------------
    sed -i "s|{{NOMBRE}}|${idx_name_sed}|g; s|{{VERSION}}|2.0|g; s|<h1>Hola Docker</h1>|<h1>Hola Docker (v2)</h1>|g" "${workdir}/index.html" || true

    echo
    echo -e "${C_BOLD}Comandos (v2)${C_RESET}"
    echo "docker build -t ${DIDACTICA_IMAGEN_WEB_V2} ."
    echo "docker run -d --name ${DIDACTICA_CONTENEDOR_WEB_V2} -p ${port2}:80 ${DIDACTICA_IMAGEN_WEB_V2}"
    echo "docker ps"
    echo "docker logs --tail 30 ${DIDACTICA_CONTENEDOR_WEB_V2}"
    if [[ "$exec_shell" -eq 1 ]]; then
        echo "docker exec -it ${DIDACTICA_CONTENEDOR_WEB_V2} sh"
    fi

    if [[ "$run_auto" -eq 1 ]]; then
        if [[ "$delete_v1" -eq 1 ]]; then
            docker stop "${DIDACTICA_CONTENEDOR_WEB_V1}" >/dev/null 2>&1 || true
            docker rm -f "${DIDACTICA_CONTENEDOR_WEB_V1}" >/dev/null 2>&1 || true
        fi

        docker rm -f "${DIDACTICA_CONTENEDOR_WEB_V2}" >/dev/null 2>&1 || true
        (cd "$workdir" && docker build -t "${DIDACTICA_IMAGEN_WEB_V2}" .)
        docker run -d --name "${DIDACTICA_CONTENEDOR_WEB_V2}" -p "${port2}:80" "${DIDACTICA_IMAGEN_WEB_V2}" >/dev/null
        docker ps
        docker logs --tail 30 "${DIDACTICA_CONTENEDOR_WEB_V2}" || true
        if [[ "$exec_shell" -eq 1 ]]; then
            docker exec -it "${DIDACTICA_CONTENEDOR_WEB_V2}" sh
        fi
        echo -e "${C_GREEN}Acceso recomendado: http://localhost:${port2}${C_RESET}"
    else
        msg_aviso "Ejecucion automatica desactivada para v2."
    fi

    echo
    echo -e "${C_DIM}Nota:${C_RESET} se ha creado un directorio temporal en: $tmp_workdir"
    pausa
}

op_module_practica_compose_web() {
    verificar_docker || return
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Practica con Compose: proyecto web multicomponente reproducible${C_RESET}"
    echo

    if [[ ! -f "${DIDACTICA_DIR_EJEMPLO_WEB}/compose.yaml" ]]; then
        msg_error "No existe el template de compose en: $DIDACTICA_DIR_EJEMPLO_WEB"
        pausa
        return 1
    fi

    local nombre port run_auto
    read -r -p "Tu nombre [opcional]: " nombre
    nombre="${nombre:-}"

    read -r -p "Puerto host para Compose [8080]: " port
    port="${port:-8080}"

    if pedir_si_no "Ejecutar automaticamente docker compose up (y down)?" "s"; then
        run_auto=1
    else
        run_auto=0
    fi

    local tmp_workdir workdir idx_name_sed
    tmp_workdir="$(mktemp -d)"
    workdir="${tmp_workdir}/web-compose-clase"
    mkdir -p "$workdir"
    cp -a "${DIDACTICA_DIR_EJEMPLO_WEB}/." "$workdir/"

    idx_name_sed="$(printf '%s' "$nombre" | sed -e 's/[\/&]/\\&/g')"
    sed -i "s|{{NOMBRE}}|${idx_name_sed}|g; s|{{VERSION}}|1.0|g; s|<h1>Hola Docker</h1>|<h1>Hola Docker</h1>|g" "${workdir}/index.html" || true

    echo
    echo -e "${C_BOLD}Comandos (Compose)${C_RESET}"
    echo "cd \"$workdir\""
    echo "HOST_PORT=${port} docker compose up -d --build"
    echo "docker compose ps"
    echo "docker compose logs -f"
    echo "docker compose down"

    if [[ "$run_auto" -eq 1 ]]; then
        # Evita choques con el container_name fijo del template
        docker rm -f web-compose >/dev/null 2>&1 || true

        (cd "$workdir" && HOST_PORT="${port}" docker compose up -d --build)
        (cd "$workdir" && docker compose ps)
        (cd "$workdir" && docker compose logs --tail=50)

        pedir_si_no "Parar y borrar recursos (docker compose down)?" "N" && (cd "$workdir" && docker compose down) || true
        echo -e "${C_GREEN}Acceso recomendado: http://localhost:${port}${C_RESET}"
    else
        msg_aviso "Ejecucion automatica desactivada para Compose."
    fi

    echo
    echo -e "${C_DIM}Directorio temporal: $tmp_workdir${C_RESET}"
    pausa
}

op_module_intercambio_entre_equipos() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Intercambio entre equipos (Docker Hub o compartir proyecto)${C_RESET}"
    echo
    cat << 'EOF'
Opcion A: publicar en Docker Hub
1) Crear cuenta en Docker Hub.
2) Iniciar sesion:
   docker login
3) Etiquetar imagen:
   docker tag web-docker-practica:1.0 usuario/web-docker-practica:1.0
4) Publicar:
   docker push usuario/web-docker-practica:1.0
5) En otro equipo:
   docker pull usuario/web-docker-practica:1.0
   docker run -d --name web-remota -p 8080:80 usuario/web-docker-practica:1.0

Opcion B: compartir el proyecto (carpeta con Dockerfile + index.html + compose.yaml)
1) Compartir la carpeta con otra persona o equipo.
2) En el otro equipo, construir localmente:
   docker build -t web-docker-practica:1.0 .
3) O usa compose para un arranque declarativo:
   docker compose up --build
EOF
    echo
    pausa
}

op_module_diferencias_mac_ubu_windows() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Diferencias utiles entre macOS, Ubuntu y Windows${C_RESET}"
    echo
    cat << 'EOF'
Aspecto                      macOS                          Ubuntu                           Windows
-----------------------------------------------------------------------------------------------
Instalacion recomendada     Docker Desktop.              Docker Desktop o Docker Engine.  Docker Desktop.
Backend o base              Docker Desktop para Mac.     Desktop para Linux o Engine nativo.
                            (escritorio).                (formacion tecnica: Engine).     WSL 2 o Hyper-V.
Terminal habitual           Terminal/iTerm.              Bash en terminal del sistema.     PowerShell/Windows Terminal/WSL.
Verificacion inicial        docker version/info/hello-world.   docker version/info/hello-world.  docker version/info/hello-world.
EOF
    echo
    pausa
}

op_module_errores_frecuentes() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Errores frecuentes y solucion (para no atascarse al practicar)${C_RESET}"
    echo
    cat << 'EOF'
1) El comando docker no funciona
- Causas habituales:
  - Docker Desktop no iniciado.
  - Instalacion incompleta.
  - Permisos insuficientes (en Ubuntu: usuario no en grupo docker).
- Solucion:
  - Iniciar Docker Desktop.
  - En Ubuntu: sudo usermod -aG docker $USER, cerrar sesion y volver a entrar.

2) El puerto 8080 esta ocupado
- Solucion:
  - Cambiar mapeo, p.ej. -p 8081:80
  - O cerrar el servicio que lo usa.

3) El contenedor arranca y se detiene enseguida
- Indica que el proceso principal termino por error o finalizo.
- En nginx:alpine no deberia pasar si el comando/imagen son correctos.

4) No se ven los cambios al editar el HTML
- Clave didactica:
  - El contenedor depende de la imagen.
  - Hay que reconstruir (docker build) y relanzar el contenedor.
EOF
    echo
    pausa
}

operacion_modulo_actividades_practica() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Actividades de practica (5 propuestas)${C_RESET}"
    echo
    cat << 'EOF'
Actividad 1. Reconocimiento de conceptos
- Identifica en un esquema: imagen, contenedor, Dockerfile, registry, volumen, puerto.
- Explica por que una imagen no es lo mismo que un contenedor.

Actividad 2. Instalacion y prueba
- Instala Docker en tu equipo.
- Documenta con: docker version, docker info y docker run hello-world.

Actividad 3. Primera web en contenedor
- Construye y arranca la practica principal.
- Accede desde el navegador.
- Revisa logs y cambia el HTML para generar una segunda version.

Actividad 4. Compose
- Transforma la practica para usar compose.yaml.
- Arranca con docker compose up -d.
- Detener con docker compose down.

Actividad 5. Intercambio entre equipos
- Sube la imagen a un registro o comparte el proyecto.
- Ejecuta la misma practica en otro equipo (otro sistema operativo).
EOF
    echo
    pausa
}

op_module_rubrica_evaluacion() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Criterios de autoevaluacion${C_RESET}"
    echo
    cat << 'EOF'
Criterio                            Excelente                                    Correcto                     Insuficiente
---------------------------------------------------------------------------------------------------------------
Instalacion                          Docker instalado y validado sin errores.      Con ayuda puntual.           No completa/valida.

Comprension conceptual              Diferencia claramente imagen/cont.           Distingue con dudas menores. Confunde conceptos base.

Uso de comandos                      Usa con soltura build/run/ps/logs/stop/rm/Compose.  Usa lo basico con apoyo. No maneja el flujo.

Practica                            Construye, ejecuta, modifica y relanza.     Completa casi todo.         No logra la practica funcional.

Portabilidad                        Comparte o replica en otro sistema.         Entiende el proceso a medias. No demuestra portabilidad.
EOF
    echo
    pausa
}

op_module_anexo_secuencia_minima() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Anexo: secuencia minima para pizarra${C_RESET}"
    echo
    cat << 'EOF'
docker version
docker info
docker run hello-world
docker pull nginx:alpine
docker images
docker build -t web-docker-practica:1.0 .
docker run -d --name web-clase -p 8080:80 web-docker-practica:1.0
docker ps
docker logs web-clase
docker exec -it web-clase sh
docker stop web-clase
docker rm web-clase
docker compose up -d
docker compose down
EOF
    echo
    pausa
}

op_module_anexo_practica_alternativa() {
    clear 2>/dev/null || true
    echo -e "${C_BOLD}Anexo: practica breve alternativa${C_RESET}"
    echo
    cat << 'EOF'
Si se quiere una practica todavia mas corta (pre-practica antes de Dockerfile y Compose),
puede ejecutarse directamente una imagen oficial:

docker run -d --name ejemplo-nginx -p 8080:80 nginx:alpine

Luego:
1) Visitar http://localhost:8080
2) Revisar logs si hace falta:
   - docker logs ejemplo-nginx
3) Eliminar:
   - docker stop ejemplo-nginx
   - docker rm ejemplo-nginx
EOF
    echo
    pausa
}

op_module_dockerfile_y_flujo() {
    op_module_instrucciones_dockerfile
    op_module_buenas_practicas_y_flujo
}

menu_modulos_didacticos() {
    while true; do
        mostrar_banner
        echo -e "${C_BOLD}Modulos didacticos (apuntes completos)${C_RESET}"
        echo
        echo "  1) Instalacion por sistema (Mac/Ubuntu/Windows)"
        echo "  2) Conceptos esenciales"
        echo "  3) Mapa mental (flujo basico)"
        echo "  4) Catalogo de comandos esenciales"
        echo "  5) Dockerfile: instrucciones clave + buenas practicas"
        echo "  6) Practica guiada principal (Dockerfile + versionado)"
        echo "  7) Practica guiada con Compose"
        echo "  8) Compartir entre equipos"
        echo "  9) Diferencias macOS/Ubuntu/Windows"
        echo "  10) Errores frecuentes y solucion"
        echo "  11) Actividades de practica"
        echo "  12) Criterios de autoevaluacion"
        echo "  13) Anexo: secuencia minima (pizarra)"
        echo "  14) Anexo: practica breve alternativa"
        echo
        echo "   0) Volver"
        echo
        echo -e "${C_DIM}  Cada actividad se abre en una ventana nueva (el menu queda aqui).${C_RESET}"
        echo
        read -r -p "Selecciona una opcion: " choice
        case "$choice" in
            1)  qw_launch "Instalacion por SO" mostrar_instalacion_por_so ;;
            2)  qw_launch "Conceptos esenciales" op_module_conceptos_esenciales ;;
            3)  qw_launch "Mapa mental" op_module_mapa_mental ;;
            4)  qw_launch "Catalogo de comandos" op_module_catalogo_comandos ;;
            5)  qw_launch "Dockerfile y buenas practicas" op_module_dockerfile_y_flujo ;;
            6)  qw_launch "Practica Dockerfile" op_module_practica_dockerfile_web ;;
            7)  qw_launch "Practica Compose" op_module_practica_compose_web ;;
            8)  qw_launch "Compartir entre equipos" op_module_intercambio_entre_equipos ;;
            9)  qw_launch "Diferencias SO" op_module_diferencias_mac_ubu_windows ;;
            10) qw_launch "Errores frecuentes" op_module_errores_frecuentes ;;
            11) qw_launch "Actividades de practica" operacion_modulo_actividades_practica ;;
            12) qw_launch "Autoevaluacion" op_module_rubrica_evaluacion ;;
            13) qw_launch "Anexo pizarra" op_module_anexo_secuencia_minima ;;
            14) qw_launch "Anexo nginx rapido" op_module_anexo_practica_alternativa ;;
            0) return ;;
            *) msg_error "Opcion no valida."; pausa ;;
        esac
    done
}
