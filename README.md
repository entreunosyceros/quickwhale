# QuickWhale v1.0 — «Aprendiendo Bash»

<img width="1408" height="768" alt="quickwhale" src="https://github.com/user-attachments/assets/184f1c67-233e-43e8-881a-ef4077dc68c6" />

**QuickWhale** es solo un asistente interactivo en Bash para **instalar Docker y Composer en Ubuntu**, aprender Docker de forma guiada y **gestionar tus propios contenedores, archivos Compose y páginas HTML** para así no tener que memorizar todos los comandos de la CLI.


Cada acción importante se abre en **una ventana de terminal nueva**, de modo que el **menú principal sigue visible** mientras trabajas.

---

## Requisitos

- **Ubuntu** 20.04 o superior (otras distros pueden funcionar con limitaciones).
- Permisos de **sudo** para la instalación de paquetes.
- Conexión a Internet (descarga de imágenes, repositorios, Composer).
- Para ventanas nuevas: entorno de escritorio con terminal gráfica (`gnome-terminal`, `konsole`, `xfce4-terminal`, `xterm`, `alacritty`, `kitty`, etc.). Sin GUI, las actividades se ejecutan en la misma terminal.

---

## Instalación rápida

### Desde GitHub

```bash
git clone https://github.com/entreunoysceros/quickwhale.git
cd quickwhale
chmod +x quickwhale.sh
```

### Instalar Docker, Composer y comando global

```bash
# Instalación completa (Docker + Composer + enlace en /usr/local/bin)
sudo ./quickwhale.sh install

# O solo el enlace global (si ya tienes Docker)
sudo ./quickwhale.sh link
```

Tras instalar Docker, el script añade tu usuario al grupo `docker`. **Cierra sesión y vuelve a entrar** para usar Docker sin `sudo`.

Comprueba el entorno:

```bash
./quickwhale.sh status
# o, tras instalar el enlace global:
quickwhale status
```

---

## Uso básico

### Menú interactivo

```bash
./quickwhale.sh
# o:
quickwhale
```

Al iniciar verás el banner de **QuickWhale** y el menú principal. Las acciones se lanzan en ventana nueva cuando el sistema lo permite.

### Comandos directos

| Comando | Descripción |
|---------|-------------|
| `./quickwhale.sh` | Menú principal |
| `./quickwhale.sh install` | Instalar Docker + Composer + comando `quickwhale` |
| `./quickwhale.sh link` | Crear enlace en `/usr/local/bin/quickwhale` |
| `./quickwhale.sh docker` | Operaciones Docker (todos los contenedores) |
| `./quickwhale.sh didactic` | Módulos didácticos (apuntes y prácticas) |
| `./quickwhale.sh projects` | Mis proyectos personales |
| `./quickwhale.sh text` | Modo lenguaje natural |
| `./quickwhale.sh demo` | Demo Compose de ejemplo (`ejemplos/`) |
| `./quickwhale.sh status` | Estado de Docker, Composer y proyecto activo |
| `./quickwhale.sh credits` | Créditos y abrir repositorio en el navegador |
| `./quickwhale.sh help` | Ayuda en terminal |

---

## Menú principal

| Opción | Función |
|--------|---------|
| **1** | Instalar Docker y/o Composer |
| **2** | **Operaciones Docker** — gestiona **cualquier** contenedor del sistema |
| **3** | Operaciones Composer (`install`, `update`, comandos personalizados) |
| **4** | **Estado y servicios** — iniciar/parar/reiniciar Docker, permisos, verificar Composer |
| **5** | Demo Docker Compose (`ejemplos/`, puerto 8080) |
| **6** | **Módulos didácticos** — apuntes, catálogo de comandos, prácticas guiadas |
| **7** | **Modo lenguaje natural** — ¿Qué quieres hacer? |
| **8** | **Mis proyectos** — plantillas YAML/HTML, edición y Compose propio |
| **9** | **Créditos** — qué hace el programa y enlace al repositorio |
| **0** | Salir |

---

## Modo lenguaje natural (opción 7)

Escribe con tus palabras lo que quieres hacer con Docker. QuickWhale interpreta la frase, muestra el **comando equivalente** y pregunta si lo ejecuta.

### Submenú del modo

| Opción | Acción |
|--------|--------|
| **1** | Escribir frase (prompt interactivo `>`) |
| **2** | Ver ejemplos de frases (`ejemplos.md`) |
| **3** | Editar frases reconocidas (`intenciones.conf`) |
| **4** | Editar ejemplos (`ejemplos.md`) |

### Archivos configurables (sin tocar código)

| Archivo | Para qué sirve |
|---------|----------------|
| `configuracion/lenguaje_natural/intenciones.conf` | Frases que el programa **reconoce** (`pattern=`) |
| `configuracion/lenguaje_natural/ejemplos.md` | Referencia con tablas de frases de ejemplo |

Formato de un intent en `intenciones.conf`:

```
@LIST_RUNNING
priority=30
label=Listar contenedores en ejecución
command=docker ps
pattern=a ver qué tengo corriendo
pattern=qué tengo corriendo
```

**Prioridad:** número más bajo = se evalúa antes (frases específicas arriba).

### Ejemplos de frases

| Frase de ejemplo | Intent |
|------------------|--------|
| a ver qué tengo corriendo | `docker ps` |
| mátalo ya | `docker stop -t 0` |
| levanta el tinglado | `docker compose up -d` |
| lo he roto | reset `compose down -v` + rebuild |
| en mi máquina funciona | mensaje didáctico de portabilidad |

Acceso directo: `./quickwhale.sh text`

---

## Créditos (opción 9)

Muestra una descripción breve de QuickWhale:

- Instalación guiada de Docker Engine y Composer.
- Asistente para operaciones Docker sin memorizar la CLI.
- Módulos didácticos (conceptos, prácticas, Compose).
- Proyectos personales con plantillas YAML/HTML editables.
- Actividades en ventana nueva con el menú siempre visible.

Incluye el enlace clicable al repositorio:

**https://github.com/entreunoysceros/quickwhale**

Puedes abrirlo en el navegador por defecto del sistema (vía `xdg-open`, `sensible-browser`, etc.) o acceder directamente:

```bash
./quickwhale.sh credits
```

---

## Ventanas nuevas y menú siempre visible

Al elegir una actividad (por ejemplo «Listar contenedores» o «Editar YAML»), QuickWhale intenta abrirla en **otra terminal del sistema** (la misma que usa tu escritorio). El menú en la ventana original **no se cierra**.

**Orden de preferencia:** `x-terminal-emulator` / `xdg-terminal-exec` (terminal por defecto del SO) → emulador del escritorio (GNOME, KDE, XFCE…) → otros.

Si falta el emulador o D-Bus (`dbus-x11`), QuickWhale puede **instalar automáticamente** `gnome-terminal`, `xdg-utils` y `dbus-x11` (con confirmación sudo). También: menú **1 → 5** (Instalar emulador de terminal).

Variable opcional: `export QUICKWHALE_TERMINAL=gnome-terminal`

Si no hay entorno gráfico (SSH sin X11), la acción se ejecuta en la misma terminal.

---

## Arquitectura modular

QuickWhale está dividido en un **punto de entrada mínimo** (`quickwhale.sh`, ~90 líneas) y módulos cargados en tiempo de ejecución:

```
quickwhale.sh          →  lib/arranque.sh  →  carga lib/* y modulos/*
```

| Componente | Responsabilidad |
|------------|-----------------|
| `lib/configuracion.sh` | Rutas, versión, URL del repositorio |
| `lib/interfaz.sh` | Banner, colores, mensajes, pausa |
| `lib/utilidades.sh` | sudo, Ubuntu, abrir URLs en navegador |
| `lib/terminal.sh` | Ventanas nuevas (`qw_launch`) |
| `lib/editor.sh` | Edición de YAML, HTML, Dockerfile |
| `modulos/instalacion.sh` | Docker, Composer, enlace global |
| `modulos/docker.sh` | Operaciones Docker |
| `modulos/composer.sh` | Operaciones Composer |
| `modulos/demos.sh` | Demos en `ejemplos/` |
| `modulos/didactica.sh` | Apuntes y prácticas guiadas |
| `modulos/proyectos.sh` | Proyectos personales del usuario |
| `modulos/servicios.sh` | Estado, servicio Docker y utilidades Composer |
| `modulos/lenguaje_natural.sh` | Modo lenguaje natural |
| `modulos/menus.sh` | Menús interactivos |

### Estructura del repositorio

```
quickwhale/
├── quickwhale.sh          # Punto de entrada
├── lib/                   # Librerías compartidas
├── modulos/               # Lógica por área funcional
├── configuracion/
│   └── lenguaje_natural/
│       ├── intenciones.conf   # Frases editables (pattern=)
│       └── ejemplos.md        # Referencia de frases de ejemplo
├── plantillas/
│   ├── compose/           # Plantillas YAML (Compose)
│   ├── html/              # Plantillas HTML
│   └── dockerfile/        # Plantillas Dockerfile
├── ejemplos/              # Demos de ejemplo
│   ├── docker-compose.yml
│   ├── html/
│   └── web-docker-practica/  # Práctica Dockerfile + Compose
└── README.md
```

### Datos del usuario (fuera del repositorio)

| Ruta | Contenido |
|------|-----------|
| `~/.quickwhale/projects/` | Proyectos personales |
| `~/.quickwhale/state` | Proyecto activo seleccionado |

---

## Módulos didácticos (opción 6)

Incluye la guía de Docker para macOS, Ubuntu y Windows:

- Instalación por sistema operativo
- Conceptos: imagen, contenedor, Dockerfile, registry, volumen, red, Compose
- Mapa mental: `pull/build → run → logs → stop → compose`
- Catálogo de comandos esenciales
- Dockerfile, buenas prácticas y flujo de trabajo
- **Práctica guiada** `web-docker-practica` (versiones 1.0 y 2.0)
- **Práctica con Compose**
- Compartir imágenes (Docker Hub) o proyectos
- Errores frecuentes, actividades de practica, lista de comprobacion y anexos

Las prácticas usan `ejemplos/web-docker-practica/`. Los demos en `ejemplos/` (opción 5) son independientes.

Cada apartado didáctico se abre en **ventana nueva**; el submenú de módulos permanece en la terminal principal.

---

## Mis proyectos (opción 8)

Gestiona **tus contenedores y archivos fuera de los apuntes**.

### Crear un proyecto

1. Menú **8 → 2** — Crear proyecto desde plantilla.
2. Indica nombre, tu nombre (para HTML) y elige plantilla Compose y HTML.
3. Se crea en `~/.quickwhale/projects/<nombre>/` con `compose.yaml`, `html/index.html` y `.env`.

### Plantillas Compose

| Archivo | Descripción |
|---------|-------------|
| `nginx-web.compose.yaml` | Nginx con `build: .` y Dockerfile |
| `nginx-imagen.compose.yaml` | Nginx oficial + volumen `./html` |
| `php-mysql.compose.yaml` | PHP Apache + MySQL |
| `node-postgres.compose.yaml` | Node + PostgreSQL |
| `redis-cache.compose.yaml` | Redis |
| `stack-vacio.compose.yaml` | Stack mínimo para personalizar |

### Plantillas HTML

| Archivo | Descripción |
|---------|-------------|
| `index-basico.html` | Página simple personalizable |
| `docker-practica.html` | Plantilla HTML para práctica con Docker |

### Editar archivos

| Opción | Acción |
|--------|--------|
| **9** | Editar `.yml` / `.yaml` del proyecto |
| **10** | Editar archivos `.html` |
| **11** | Editar `Dockerfile` |
| **12** | Editar plantillas del sistema (afectan proyectos **nuevos**) |

### Docker Compose en tu proyecto

| Opción | Acción |
|--------|--------|
| **4** | `docker compose up` |
| **5** | `docker compose down` |
| **6** | `docker compose ps` |
| **7** | `docker compose logs` |
| **8** | `docker compose build` |

También puedes **registrar una carpeta externa** (opción 3) como proyecto activo.

### Editor de archivos

Orden de preferencia:

1. `QUICKWHALE_EDITOR`
2. `EDITOR`
3. Primer disponible: `nano`, `vim`, `vi`, `micro`, `code`, `codium`

```bash
export QUICKWHALE_EDITOR=nano
quickwhale projects
```

---

## Operaciones Docker (opción 2)

Gestiona **todos los contenedores e imágenes** del equipo:

- Listar, iniciar, detener, reiniciar contenedores
- Logs y `exec` interactivo
- `docker run` asistido
- Pull, build, eliminar imágenes
- Compose en cualquier carpeta
- Limpieza (`prune`)

---

## Flujo recomendado

### Primeros pasos

1. `quickwhale install` (o Docker ya instalado).
2. Menú **6** → prácticas guiadas y `hello-world`.
3. Menú **5** → demo Nginx en `http://localhost:8080`.

### Proyecto personal

1. Menú **8 → 2** — Crear proyecto.
2. Menú **8 → 10** — Editar HTML.
3. Menú **8 → 9** — Ajustar `compose.yaml`.
4. Menú **8 → 4** — `compose up`.
5. Tras cambios en HTML/Dockerfile: **reconstruir** (`compose build` o `up --build`).

### Regla importante

Si el HTML está **dentro de la imagen** (`COPY` en Dockerfile), hay que **reconstruir** y recrear el contenedor. Con **volúmenes** (`nginx-image`), suele bastar recargar el navegador.

---

## Solución de problemas

| Problema | Qué hacer |
|----------|-----------|
| `docker: command not found` | Menú **1** o `sudo ./quickwhale.sh install` |
| `permission denied` en Docker | Menú **4 → 6** (grupo docker) o `sudo usermod -aG docker $USER` y cerrar sesión |
| Docker no responde / daemon parado | Menú **4 → 2** (iniciar) o **4 → 4** (reiniciar) |
| No se abren ventanas nuevas | Normal en SSH sin X11; usa la misma terminal |
| Puerto 8080 ocupado | Cambia `HOST_PORT` en `.env` o en `compose.yaml` |
| No se ven cambios en HTML | Reconstruye imagen y relanza contenedor |
| `quickwhale` no encontrado | `sudo ./quickwhale.sh link` |
| Enlace GitHub no abre | Menú **9** o abre manualmente la URL del repositorio |

---

## Autoría y repositorio

**QuickWhale v1.0 — «Aprendiendo Bash»**

Proyecto educativo para aprender Docker en Ubuntu: apoyo didáctico, asistente de comandos y proyectos personales reproducibles con Compose.

- **Autor:** [entreunosyceros](https://github.com/entreunoysceros)
- **Repositorio:** [https://github.com/entreunoysceros/quickwhale](https://github.com/entreunoysceros/quickwhale)
