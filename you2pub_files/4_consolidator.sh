#!/bin/bash

# ===============================================
# 4_consolidator.sh
# Verifica la integridad de los videos y subtítulos descargados y reintenta
# la descarga de archivos faltantes o corruptos. Lee la resolución desde
# el archivo 'xcron' de cada carpeta principal.
# Uso: ./4_consolidator.sh
# ===============================================

# --- Constantes de Directorio y Archivos ---
DOWNLOAD_ROOT="$HOME/public_html/You2Pub"
ID_LIST_FILENAME="video_ids_for_download.txt"
XCRON_FILENAME="xcron"
SUBTITLE_LANGUAGES="es,en,fr,de,pt,it,ru,zh,ja" # Lista de idiomas a verificar
VIDEO_FILENAME_PATTERN="%(id)s.%(ext)s" # El patrón usado en los scripts de descarga
VIDEO_EXTENSION="mp4"
THUMBNAIL_EXTENSION="jpg"

# Colores
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# ----------------------------------------------------------------------------------
# 🛠️ FUNCIONES DE VERIFICACIÓN Y REPARACIÓN
# ----------------------------------------------------------------------------------

# Verifica la integridad del archivo de video usando ffprobe.
# Retorna 0 si es OK, 1 si falla o no existe.
check_video_integrity() {
    local VIDEO_FILE="$1"
    
    if [ ! -f "$VIDEO_FILE" ]; then
        echo -e "  [FAIL] Video no encontrado: ${RED}$VIDEO_FILE${NC}"
        return 1
    fi

    # ffprobe retorna 1 si no puede leer los metadatos de duración (corrupto/incompleto)
    # Suprimimos la salida con -v error
    # Necesitas tener ffprobe/ffmpeg instalado para que esta comprobación funcione.
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "  [FAIL] Video encontrado, pero ${RED}parece corrupto/incompleto${NC}."
        return 1
    fi
    
    echo -e "  [OK] Video principal verificado."
    return 0
}

# ----------------------------------------------------------------------------------
# 🔑 PASO A: Consolidar la lista de IDs de videos
# ----------------------------------------------------------------------------------

echo -e "\n${YELLOW}=== Paso A: Consolidando todos los IDs de videos... ===${NC}"

# 1. Buscar y concatenar todos los archivos ID_LIST_FILENAME, y obtener IDs únicos
mapfile -t ALL_VIDEO_IDS < <(find "$DOWNLOAD_ROOT" -name "$ID_LIST_FILENAME" -exec cat {} + 2>/dev/null | sort -u)

if [ ${#ALL_VIDEO_IDS[@]} -eq 0 ]; then
    echo -e "${RED}❌ No se encontraron IDs de video para procesar en '$DOWNLOAD_ROOT'.${NC}"
    exit 0
fi

TOTAL_VIDEOS=${#ALL_VIDEO_IDS[@]}
echo -e "${GREEN}✔ Encontrados $TOTAL_VIDEOS IDs únicos para verificar.${NC}"

# ----------------------------------------------------------------------------------
# 🔑 PASO B: Iteración y Verificación
# ----------------------------------------------------------------------------------
PROCESSED_COUNT=0

for VIDEO_ID in "${ALL_VIDEO_IDS[@]}"; do
    PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
    NEEDS_REPAIR=0 # Flag para saber si se necesita pausar

    echo -e "\n${YELLOW}===================================================================${NC}"
    echo -e "${YELLOW}🔍 Verificando Video $PROCESSED_COUNT de $TOTAL_VIDEOS: ID ${CYAN}$VIDEO_ID${NC}"
    echo -e "${YELLOW}===================================================================${NC}"

    # 1. Buscar la ubicación del directorio del video (ej: Videos/Prueba/NTuUaUuoaL0)
    VIDEO_DIR=$(find "$DOWNLOAD_ROOT" -type d -name "$VIDEO_ID" -print -quit 2>/dev/null)

    if [ -z "$VIDEO_DIR" ]; then
        echo -e "${RED}  ❌ ERROR: No se encontró la carpeta para el ID $VIDEO_ID. Saltando.${NC}"
        continue
    fi

    # 2. Obtener el directorio padre (donde se encuentra xcron)
    PARENT_DIR=$(dirname "$VIDEO_DIR")
    XCRON_FILE="$PARENT_DIR/$XCRON_FILENAME"
    VIDEO_FORMAT_FILTER="" # Resetear filtro

    # 3. Extraer la resolución y establecer el filtro de formato
    if [ -f "$XCRON_FILE" ]; then
        # Comando para extraer la resolución del archivo xcron
        RESOLUTION_ARGUMENT=$(cat "$XCRON_FILE" | cut -d ',' -f2 | tr -d '\n\r ' ) # Quitamos espacios y saltos de línea
        RESOLUTION_ARGUMENT_UPPER=$(echo "$RESOLUTION_ARGUMENT" | tr '[:lower:]' '[:upper:]')
        
        echo -e "  Resolución de descarga: ${CYAN}$RESOLUTION_ARGUMENT_UPPER${NC}"

        case "$RESOLUTION_ARGUMENT_UPPER" in
            "SD")
                VIDEO_FORMAT_FILTER="bestvideo[height<=360][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
                ;;
            "HD")
                VIDEO_FORMAT_FILTER="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
                ;;
            *)
                echo -e "${RED}  ❌ ADVERTENCIA: Resolución '$RESOLUTION_ARGUMENT' inválida. La reparación de video será saltada.${NC}"
                ;;
        esac
    else
        echo -e "${RED}  ❌ ERROR: Archivo $XCRON_FILENAME no encontrado en $PARENT_DIR. La reparación de video será saltada.${NC}"
    fi

    # 4. Cambiar al directorio del video para trabajar con rutas relativas
    CURRENT_WORKING_DIR=$(pwd)
    if ! cd "$VIDEO_DIR"; then
        echo -e "${RED}  ❌ ERROR: No se pudo entrar al directorio $VIDEO_DIR. Saltando.${NC}"
        continue
    fi
    echo -e "${GREEN}  Ubicación: $(pwd)${NC}"


    # ---------------------------------------------------
    # B1. VERIFICAR VIDEO PRINCIPAL
    # ---------------------------------------------------
    VIDEO_FILE="$VIDEO_ID.$VIDEO_EXTENSION"
    if ! check_video_integrity "$VIDEO_FILE"; then
        NEEDS_REPAIR=1
        if [ -n "$VIDEO_FORMAT_FILTER" ]; then
            echo -e "  ${CYAN}--- REPARACIÓN: Reintentando descarga del Video Principal ($RESOLUTION_ARGUMENT_UPPER) ---${NC}"
            
            # Comando de re-descarga de video
            yt-dlp \
                -f "$VIDEO_FORMAT_FILTER" \
                --recode-video mp4 \
                --write-thumbnail --convert-thumbnails jpg \
                --embed-metadata \
                --cookies-from-browser firefox \
                --limit-rate 1M \
                --extractor-args youtube:player-client=web \
                -o "$VIDEO_FILENAME_PATTERN" \
                -- "$VIDEO_ID"
                
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✔ Video Principal re-descargado con éxito.${NC}"
            else
                echo -e "${RED}  ❌ FALLO DE REPARACIÓN: No se pudo re-descargar el video. Verifique cookies.${NC}"
            fi
        else
             echo -e "${RED}  ⚠️ ADVERTENCIA: Video incompleto pero la reparación del video fue saltada (Resolución/xcron no válidos).${NC}"
        fi
    fi


    # ---------------------------------------------------
    # B2. VERIFICAR THUMBNAIL
    # ---------------------------------------------------
    THUMBNAIL_FILE="$VIDEO_ID.$THUMBNAIL_EXTENSION"
    if [ ! -f "$THUMBNAIL_FILE" ]; then
        NEEDS_REPAIR=1
        echo -e "  [FAIL] Thumbnail no encontrado: ${RED}$THUMBNAIL_FILE${NC}"
        echo -e "  ${CYAN}--- REPARACIÓN: Reintentando descarga del Thumbnail ---${NC}"
        
        # Comando para descargar solo el thumbnail
        yt-dlp \
            --write-thumbnail --convert-thumbnails jpg \
            --skip-download \
            --cookies-from-browser firefox \
            -o "$VIDEO_FILENAME_PATTERN" \
            -- "$VIDEO_ID"
            
        if [ $? -eq 0 ] && [ -f "$THUMBNAIL_FILE" ]; then
            echo -e "  ${GREEN}✔ Thumbnail re-descargado con éxito.${NC}"
        else
            echo -e "${RED}  ❌ FALLO DE REPARACIÓN: No se pudo re-descargar el thumbnail.${NC}"
        fi
    else
        echo -e "  [OK] Thumbnail verificado."
    fi

    
    # ---------------------------------------------------
    # B3. VERIFICAR SUBTÍTULOS
    # ---------------------------------------------------
    MISSING_LANGS=""
    for LANG_CODE in $(echo "$SUBTITLE_LANGUAGES" | tr ',' ' '); do
        SUB_FILE="$VIDEO_ID.$LANG_CODE.vtt"
        if [ ! -f "$SUB_FILE" ]; then
            MISSING_LANGS+="$LANG_CODE,"
        fi
    done
    
    if [ -n "$MISSING_LANGS" ]; then
        NEEDS_REPAIR=1
        MISSING_LANGS=${MISSING_LANGS%,}
        echo -e "  [FAIL] Faltan subtítulos: ${RED}$MISSING_LANGS${NC}"
        echo -e "  ${CYAN}--- REPARACIÓN: Reintentando descarga de Subtítulos Faltantes ---${NC}"

        SUBTITLE_ATTEMPTS=0
        SUBTITLE_SUCCESS=0

        for LANG_CODE_TO_REPAIR in $(echo "$MISSING_LANGS" | tr ',' ' '); do
            SUBTITLE_ATTEMPTS=$((SUBTITLE_ATTEMPTS + 1))
            
            # Comando de descarga de subtítulos para un idioma específico (como en tu script 3)
            yt-dlp \
                --sub-langs "$LANG_CODE_TO_REPAIR" \
                --write-sub --write-auto-sub \
                --sub-format vtt \
                --skip-download \
                --cookies-from-browser firefox \
                --quiet \
                --extractor-args youtube:player-client=web \
                -o "$VIDEO_FILENAME_PATTERN" \
                -- "$VIDEO_ID"
                
            if [ $? -eq 0 ]; then
                SUBTITLE_SUCCESS=$((SUBTITLE_SUCCESS + 1))
                echo -e "  ${GREEN}    ✔ Subtítulo $LANG_CODE_TO_REPAIR re-descargado con éxito.${NC}"
            else
                echo -e "${RED}  ⚠️ ADVERTENCIA: Fallo al re-descargar subtítulo $LANG_CODE_TO_REPAIR.${NC}"
            fi
            
            # Pausa aleatoria entre idiomas durante la reparación (14-37s)
            RANDOM_PAUSE_LANG=$(shuf -i 58-127 -n 1)
            echo -e "  Esperando ${CYAN}$RANDOM_PAUSE_LANG${NC} segundos antes del siguiente subtítulo de reparación..."
            sleep "$RANDOM_PAUSE_LANG"
            
        done # Fin del ciclo for de subtítulos faltantes
        
        echo -e "  ${GREEN}✔ Subtítulos: $SUBTITLE_SUCCESS de $SUBTITLE_ATTEMPTS idiomas faltantes reparados.${NC}"
    else
        echo -e "  [OK] Todos los subtítulos requeridos verificados."
    fi

    # ---------------------------------------------------
    # B4. PAUSA EXTENDIDA DE CORTESÍA SI HUBO REPARACIÓN
    # ---------------------------------------------------
    if [ "$NEEDS_REPAIR" -eq 1 ]; then
        # Pausa de más de 2-3 minutos (180 a 300 segundos)
        REPAIR_BREAK=$(shuf -i 181-307 -n 1) 
        echo -e "\n${CYAN}🚨 Hubo reparaciones. Esperando $REPAIR_BREAK segundos antes del siguiente video...${NC}"
        sleep "$REPAIR_BREAK"
    fi

    # 5. Volver al directorio principal del canal/lista
    if ! cd "$CURRENT_WORKING_DIR"; then
        echo -e "${RED}❌ ERROR FATAL: No se pudo volver al directorio original. Terminando.${NC}"
        exit 1
    fi
    
done # Fin del ciclo for de videos

# ----------------------------------------------------------------------------------
# 🔑 PASO C: Finalización
# ----------------------------------------------------------------------------------

echo -e "\n${GREEN}===================================================================${NC}"
echo -e "${GREEN} 🎉 Proceso de consolidación de $TOTAL_VIDEOS videos completado. ${NC}"
echo -e "${GREEN}===================================================================${NC}"
