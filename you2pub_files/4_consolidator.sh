#!/bin/bash
# ===============================================
# CONSOLIDADOR.sh
# Verifica la integridad de los videos y la presencia de metadatos (JSON, Thumbnail, VTT).
# Intenta reparar o descargar archivos faltantes o corruptos.
# ===============================================

# --- Constantes de Directorio y Archivos ---
DOWNLOAD_ROOT="$HOME/public_html/You2Pub"
ID_LIST_FILENAME="video_ids_for_download.txt"
XCRON_FILENAME="xcron"
SUBTITLE_LANGUAGES="es,en,fr,de,pt,it,ru,zh,ja"
VIDEO_FILENAME_PATTERN="%(id)s.%(ext)s" # El patrón usado en los scripts de descarga
VIDEO_FORMAT_FILTER=""
VIDEO_EXTENSION="mp4"
THUMBNAIL_EXTENSION="jpg"

# Colores
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'


cuenta_atras_segura() {
    seconds=$(shuf -i 183-307 -n 1); date1=$((`date +%s` + $seconds)); 
    while [ "$date1" -ge `date +%s` ]; do 
      echo -ne "Tempo faltante: $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r"; 
    done
    # 3. Pausa Decimal Aleatoria Final
    sleep "0.$(shuf -i 1-99 -n 1)"
}


# Verificar que FFPROBE está disponible para la comprobación de integridad
if ! command -v ffprobe &> /dev/null; then
    echo -e "${RED}❌ ERROR: El comando 'ffprobe' no se encontró. Necesario para verificar la integridad de los videos.${NC}"
    echo "Instale FFmpeg/FFprobe e intente de nuevo."
    exit 1
fi

# ===================================================================
# FUNCIONES DE AYUDA Y VERIFICACIÓN
# ===================================================================

# Función para configurar el filtro de formato basado en la resolución (SD o HD)
configurar_filtro_formato() {
    local resolution_arg="$1"
    
    case "$resolution_arg" in
        "SD")
            VIDEO_FORMAT_FILTER="bestvideo[height<=360][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
            ;;
        "HD")
            VIDEO_FORMAT_FILTER="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
            ;;
        *)
            # Valor de respaldo si no se encuentra o es inválido
            VIDEO_FORMAT_FILTER="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
            echo -e "  ${YELLOW}⚠️ ADVERTENCIA: Resolución '$resolution_arg' desconocida. Usando filtro HD (720p) por defecto.${NC}"
            ;;
    esac
}


# Función para verificar la integridad del archivo MP4 usando ffprobe.
# Retorna 0 si es íntegro, 1 si está incompleto o corrupto.
verificar_integridad_mp4() {
    local video_file="$1"
    
    # 1. Verificar existencia del archivo
    if [ ! -f "$video_file" ]; then
        echo -e "  ${RED}❌ MP4 faltante.${NC}"
        return 1
    fi

    # 2. Verificar si es un archivo de tamaño cero
    if [ ! -s "$video_file" ]; then
        echo -e "  ${RED}❌ MP4 encontrado, pero tiene tamaño cero.${NC}"
        return 1
    fi

    # 3. Usar ffprobe para verificar si tiene streams válidos y duración.
    if ! ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video_file" &> /dev/null; then
        echo -e "  ${RED}❌ MP4 encontrado, pero parece estar incompleto o corrupto (ffprobe falló).${NC}"
        return 1
    fi
    
    echo -e "  ${GREEN}✔ MP4 encontrado e íntegro.${NC}"
    return 0
}

# ----------------------------------------------------------------------------------
# 🔑 FASE PRINCIPAL: Recorrer Canales y Videos
# ----------------------------------------------------------------------------------

# 💡 CORRECCIÓN: Guardamos el directorio de inicio de la shell principal.
START_DIR=$(pwd)

echo -e "\n${YELLOW}===================================================================${NC}"
echo -e "${YELLOW}🚀 Iniciando Consolidación y Verificación de Videos y Metadatos...${NC}"
echo -e "${YELLOW}===================================================================${NC}"

# Recorrer todos los directorios de canales en la carpeta raíz
find "$DOWNLOAD_ROOT" -mindepth 1 -maxdepth 1 -type d | while read -r CHANNEL_DIR; do
    CHANNEL_NAME=$(basename "$CHANNEL_DIR")
    echo -e "\n${CYAN}>>> CANAL: $CHANNEL_NAME ${NC}"
    
    # 💡 CAMBIO CLAVE: Usamos PUSHD para entrar al directorio del canal.
    # > /dev/null es para suprimir el output por defecto de pushd
    if ! pushd "$CHANNEL_DIR" > /dev/null; then
        echo -e "${RED}❌ ERROR: No se pudo entrar a $CHANNEL_DIR. Saltando.${NC}"
        continue
    fi
    
    # Leer la URL del canal y la resolución original (si existe)
    if [ -f xcron ]; then
        read -r CHANNEL_URL RESOLUTION_ARGUMENT <<< "$(cat xcron | tr ',' ' ')"
        echo -e "  ${BLUE}Info: URL de origen: $CHANNEL_URL | Res. Original: $RESOLUTION_ARGUMENT${NC}"
        
        # 💡 CAMBIO: Configurar el filtro de formato basado en xcron
        configurar_filtro_formato "$RESOLUTION_ARGUMENT"
        echo -e "  ${BLUE}Filtro de formato YT-DLP establecido según la resolución: $RESOLUTION_ARGUMENT${NC}"
    else
        echo -e "  ${RED}❌ ADVERTENCIA: No se encontró el archivo xcron. Usando filtro HD por defecto.${NC}"
        CHANNEL_URL=""
        configurar_filtro_formato "HD"
    fi

    # -------------------------------------------------------------
    # --- 1. Iterar sobre los IDs de VIDEO usando el archivo de lista ---
    # -------------------------------------------------------------
    ID_LIST_FILE="video_ids_for_download.txt"

    if [ ! -f "$ID_LIST_FILE" ]; then
        echo -e "  ${RED}❌ ERROR: Archivo de lista '$ID_LIST_FILE' no encontrado en el canal. Saltando videos.${NC}"
        # 💡 CORRECCIÓN: Si falla aquí, salimos del PUSHD del canal
        popd > /dev/null 
        continue
    fi

    echo -e "  ${GREEN}✔ Lista de IDs encontrada. Procesando videos...${NC}"

    # Leer cada ID del archivo
    while read -r VIDEO_ID_RAW; do
        
        # Limpieza: Eliminar posibles espacios en blanco o retornos de carro
        VIDEO_ID=$(echo "$VIDEO_ID_RAW" | tr -d '[:space:]')
        
        # Asegurarse de que el ID es un valor no vacío
        if [ -z "$VIDEO_ID" ]; then
            continue
        fi

        echo -e "\n${YELLOW}--- Video: $VIDEO_ID ---${NC}"

        # 1. Crear la carpeta si no existe y entrar
        mkdir -p "$VIDEO_ID"
        
        # 💡 CAMBIO CLAVE: Usamos PUSHD para entrar al directorio del video.
        if ! pushd "$VIDEO_ID" > /dev/null; then
            echo -e "${RED}  ❌ ERROR CRÍTICO: No se pudo entrar al directorio del video $VIDEO_ID. Saltando.${NC}"
            continue
        fi

        # --- FASE 1: VERIFICAR Y REPARAR MP4 ---
        MP4_FILE_NAME=$(find . -maxdepth 1 -name "*.mp4" -print -quit)
        
        verificar_integridad_mp4 "$MP4_FILE_NAME"
        INTEGRITY_CHECK=$?
        
        if [ $INTEGRITY_CHECK -ne 0 ]; then
            echo -e "  ${RED}🚨 REPARACIÓN INICIADA: Intentando descargar/completar el video faltante o corrupto...${NC}"
            
            VIDEO_OUTPUT_PATTERN="%(id)s.%(ext)s"
            # Pausa anti error 429
            #sleep "$(shuf -i 29-109 -n 1).$(shuf -i 1-99 -n1)"
            cuenta_atras_segura
            yt-dlp \
                -f "$VIDEO_FORMAT_FILTER" \
                --recode-video mp4 \
                --write-thumbnail --convert-thumbnails jpg \
                --embed-metadata \
                --cookies-from-browser firefox \
                --write-info-json \
                --limit-rate 1M \
                --extractor-args youtube:player-client=web \
                -o "$VIDEO_OUTPUT_PATTERN" \
                --force-overwrites \
                -- "$VIDEO_ID"
                
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✔ REPARACIÓN EXITOSA: Video completado/re-descargado.${NC}"
            else
                echo -e "  ${RED}❌ REPARACIÓN FALLIDA: No se pudo descargar el video $VIDEO_ID.${NC}"
            fi
        fi



        # --- FASE 2: VERIFICAR Y REPARAR METADATOS Y SUBTÍTULOS ---
        
        # A. Info JSON
        if ! find . -maxdepth 1 -name "*.info.json" -print -quit 2>/dev/null; then
            echo -e "  ${YELLOW}⚠️ Info JSON faltante. Intentando descargar metadatos...${NC}"

            # Pausa anti error 429
            #sleep "$(shuf -i 29-109 -n 1).$(shuf -i 1-99 -n1)"
            cuenta_atras_segura
            yt-dlp \
                --cookies-from-browser firefox \
                --write-info-json \
                --skip-download \
                -o "%(id)s.%(ext)s" \
                -- "$VIDEO_ID" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✔ Info JSON reparado.${NC}"
            else
                echo -e "  ${RED}❌ Fallo al descargar Info JSON.${NC}"
            fi
        fi

        # B. Thumbnail (Carátula JPG)
        if ! find . -maxdepth 1 -name "*.jpg" -print -quit 2>/dev/null; then
            echo -e "  ${YELLOW}⚠️ Carátula JPG faltante. Intentando descargar thumbnail...${NC}"

            # Pausa anti error 429
            cuenta_atras_segura  #sleep "$(shuf -i 29-109 -n 1).$(shuf -i 1-99 -n1)"

            yt-dlp \
                --cookies-from-browser firefox \
                --write-thumbnail --convert-thumbnails jpg \
                --skip-download \
                -o "%(id)s.%(ext)s" \
                -- "$VIDEO_ID" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✔ Carátula JPG reparada.${NC}"
            else
                echo -e "  ${RED}❌ Fallo al descargar Carátula JPG.${NC}"
            fi
        fi
        
# C. Subtítulos VTT (Verifica y repara cada idioma faltante con manejo de errores 429)
        echo -e "  ${CYAN}--- FASE 2/2: Verificando y Descargando Subtítulos Idioma por Idioma (formato VTT) ---${NC}"
        
        LANGUAGES_ARRAY=$(echo "$SUBTITLE_LANGUAGES" | tr ',' ' ')
        SUBTITLE_SUCCESS=0
        SUBTITLE_ATTEMPTS=0

        for LANG_CODE in $LANGUAGES_ARRAY; do
            SUB_FILE_NAME="$VIDEO_ID.$LANG_CODE.vtt"
            SUBTITLE_ATTEMPTS=$((SUBTITLE_ATTEMPTS + 1))

            # 1. CHECK: Si el archivo del idioma ya existe, saltar
            if [ -f "$SUB_FILE_NAME" ]; then
                echo -e "  ${BLUE}✔ Subtítulo '$LANG_CODE' ya existe.${NC}"
                SUBTITLE_SUCCESS=$((SUBTITLE_SUCCESS + 1)) # Contar como éxito ya que existe
                continue # Pasar al siguiente idioma
            fi

            # Si no existe, intentar la descarga con manejo de errores 429

            # 2. Ejecutar yt-dlp y CAPTURAR LA SALIDA DE ERROR (stderr) en YTDLP_ERROR
            echo -e "  ${YELLOW}⚠️ Subtítulo '$LANG_CODE' faltante. Intentando descargar...${NC}"

            # Pausa anti error 429
            cuenta_atras_segura    #sleep "$(shuf -i 29-109 -n 1).$(shuf -i 1-99 -n1)"

            # 2>&1 redirige stderr a stdout, y la subshell $(...) captura todo.
            YTDLP_ERROR=$(yt-dlp \
            --cookies-from-browser firefox \
            --write-sub \
            --write-auto-sub \
            --sub-format vtt \
            --sub-lang "$LANG_CODE" \
            -o "%(id)s.%(ext)s" \
            --skip-download -- "$VIDEO_ID" 2>&1 >/dev/null) # Redirige salida normal a /dev/null
        
            EXIT_CODE_LANG=$? # Capturamos el código de salida

            # 3. COMPROBACIÓN CRÍTICA DEL ERROR 429
            if echo "$YTDLP_ERROR" | grep -q "429"; then
                echo -e "${RED}🚨 LÍMITE 429 DETECTADO! Se detiene la descarga de subtítulos para el video actual.${NC}"
                break # 🛑 ¡SALIR DEL BUCLE DE IDIOMAS!
            fi
            
            # 4. COMPROBACIÓN DE ÉXITO (El archivo debería existir si el código de salida fue 0)
            if [ $EXIT_CODE_LANG -eq 0 ] && [ -f "$SUB_FILE_NAME" ]; then
                SUBTITLE_SUCCESS=$((SUBTITLE_SUCCESS + 1))
                echo -e "  ${GREEN}    ✔ Subtítulo $LANG_CODE descargado con éxito.${NC}"
            elif [ $EXIT_CODE_LANG -ne 1 ]; then
                # El código 1 es la salida estándar de "Subtítulo no disponible".
                # Cualquier otro código de salida (aparte de 0 o 1) es un error real.
                echo -e "${RED}  ⚠️ ADVERTENCIA: Error al descargar subtítulo $LANG_CODE (Código $EXIT_CODE_LANG).${NC}"
            fi

            # 5. Pausa aleatoria entre idiomas
            # Si no se detectó el 429, continuamos con la pausa normal
            if [ "$LANG_CODE" != "$(echo "$SUBTITLE_LANGUAGES" | rev | cut -d',' -f1 | rev)" ]; then
                RANDOM_PAUSE_LANG="$(shuf -i 30-109 -n 1).$(shuf -i 1-99 -n1)"
                echo -e "  Esperando ${CYAN}$RANDOM_PAUSE_LANG${NC} segundos antes del siguiente idioma...${NC}"
                sleep "$RANDOM_PAUSE_LANG"
            fi
        
        done # Fin del ciclo for de subtítulos

        if [ $SUBTITLE_SUCCESS -gt 0 ]; then
            echo -e "  ${GREEN}✔ Subtítulos: $SUBTITLE_SUCCESS de $SUBTITLE_ATTEMPTS idiomas intentados se verificaron/descargaron con éxito.${NC}"
        else
            echo -e "${RED}  ⚠️ ADVERTENCIA FASE 2: No se pudo verificar/descargar ningún subtítulo para ID $VIDEO_ID.${NC}"
        fi


        # 💡 CAMBIO CLAVE: Usamos POPD para salir del directorio del video.
        popd > /dev/null
        echo -e "${GREEN}✔ Saliendo de la carpeta de video. Ubicación actual: $(pwd)${NC}"
        
    done < "$ID_LIST_FILE" # Cierre del ciclo WHILE de IDs

    # 💡 CAMBIO CLAVE: Usamos POPD para salir del directorio del canal.
    popd > /dev/null
    
done

# ----------------------------------------------------------------------------------
# 🔑 PASO FINAL: Limpieza y Fin
# ----------------------------------------------------------------------------------

# 💡 CORRECCIÓN: Volvemos al directorio inicial de la shell principal.
if [ "$START_DIR" != "$(pwd)" ]; then
    echo -e "\n${CYAN}Volviendo al directorio inicial: $START_DIR...${NC}"
    cd "$START_DIR"
fi

echo -e "\n${GREEN}===================================================================${NC}"
echo -e "${GREEN} 🎉 Proceso de Consolidación finalizado. Ubicación final: $(pwd) ${NC}"
echo -e "${GREEN}===================================================================${NC}"

