# Ejemplos de frases — Modo lenguaje natural QuickWhale

Este archivo es **documentación editable**. Puedes ampliarlo con nuevos ejemplos de frases.
QuickWhale lo muestra desde el menú: **Modo lenguaje natural → Ver documentación**.

Las frases que el programa **reconoce de verdad** están en `intenciones.conf` (mismo directorio).
Si añades un ejemplo aquí, recuerda copiar también el `pattern=` correspondiente en `intenciones.conf`.

---

## Contenedores (ejecución / estado)

| Frase de ejemplo | Comando equivalente |
|------------------|---------------------|
| a ver qué tengo corriendo | `docker ps` |
| qué contenedores hay, aunque estén parados | `docker ps -a` |
| ese contenedor no me arranca | `docker logs <nombre>` |
| quiero ver lo que escupe | `docker logs --tail 50 -f <nombre>` |
| mátalo ya | `docker stop <nombre>` |
| que no hay manera de pararlo | `docker stop -t 0 <nombre>` (forzar) |
| quiero meterle una consola | `docker exec -it <nombre> sh` |
| no sé cómo se llama ese bicho | listar contenedores y elegir |

---

## Imágenes y builds

| Frase de ejemplo | Comando equivalente |
|------------------|---------------------|
| me ha dicho que la imagen no existe | `docker pull <imagen>` |
| bájate la de nginx | `docker pull nginx:alpine` |
| me he dejado una imagen tirada | `docker images` |
| borra esa imagen que pesa un huevo | `docker rmi <imagen>` |
| no hay manera de quitarla | `docker rmi -f <imagen>` |
| que me he equivocado con la etiqueta | `docker tag <vieja> <nueva>` |
| construye el chisme | `docker build -t <nombre> .` |

---

## Docker Compose

| Frase de ejemplo | Comando equivalente |
|------------------|---------------------|
| levanta el tinglado | `docker compose up -d` |
| que se vea lo que pasa | `docker compose up` (sin `-d`) |
| lo has roto, bájalo todo | `docker compose down` |
| bájalo y que se lleve los datos también | `docker compose down -v` |
| qué servicios tengo ahí | `docker compose ps` |
| enséñame la basura que escupe | `docker compose logs --tail=100` |
| sígueme los logs | `docker compose logs -f` |
| reconstruye que he cambiado el Dockerfile | `docker compose build` |
| sube pero reconstruyendo primero | `docker compose up -d --build` |
| no me acuerdo qué compose tengo activo | `docker compose ls` |

---

## Puertos y redes

| Frase de ejemplo | Comando equivalente |
|------------------|---------------------|
| no me deja usar el 8080 | `sudo lsof -i :8080` |
| me sale que el puerto ya está en uso | diagnosticar proceso + cambiar puerto |
| no veo la página | `docker ps` + logs + revisar puerto |
| cámbiale el puerto a este | `-p 8081:80` o editar `compose.yaml` |

---

## Limpieza y mantenimiento

| Frase de ejemplo | Comando equivalente |
|------------------|---------------------|
| tengo mucho cacharro parado | `docker system prune` |
| límpialo todo, hasta lo que no he usado nunca | `docker system prune -a` |
| y los volúmenes también | `docker system prune -a --volumes` |
| esto pesa más que mi ex | `docker system df` |
| borra los contenedores que están muertos | `docker container prune` |
| borra las imágenes que no uso | `docker image prune -a` |

---

## Frases de frustración

| Frase de ejemplo | Qué hace QuickWhale |
|------------------|---------------------|
| no funciona | Diagnóstico: `docker ps` + sugerencias |
| he seguido los pasos y no | Reset: `compose down -v` + rebuild |
| lo he roto | `compose down -v` + `up -d --build` |
| esto no hay quien lo entienda | Abre conceptos básicos (didáctica) |
| me da pereza mirar los comandos | Práctica guiada automática |
| en mi máquina funciona | Recordatorio: Docker = misma imagen en cualquier sitio |

---

## Cómo añadir una frase nueva

1. Edita `intenciones.conf` y busca el bloque `@ID` adecuado (o crea uno nuevo).
2. Añade una línea `pattern=tu frase en minúsculas`.
3. (Opcional) Documenta el ejemplo en este archivo.
4. Guarda y vuelve a probar en el modo lenguaje natural.

### Ejemplo de bloque en `intenciones.conf`

```
@LIST_RUNNING
priority=30
label=Listar contenedores en ejecución
command=docker ps
pattern=a ver qué tengo corriendo
pattern=qué tengo corriendo
```

**Prioridad:** número más bajo = se evalúa antes. Pon frases más específicas con prioridad baja.

---

## Comandos útiles del modo

| Escribir en el prompt | Acción |
|-----------------------|--------|
| `ayuda` / `help` | Ver resumen de frases |
| `documentacion` / `docs` | Abrir este archivo |
| `salir` / `volver` | Volver al menú |
