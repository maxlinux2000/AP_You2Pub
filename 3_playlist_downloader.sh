#!/bin/bash

# ===============================================
# 3_playlist_downloader.sh
# Gestiona la descarga de una Playlist o un Canal con estructura de Playlist.
# ===============================================

# --- Variables de Entrada (Pasadas desde 1_downloader.sh) ---
ID_O_URL="$1"
RESOLUTION_ARGUMENT="$2"

# --- Constantes ---
SUBTITLE_LANGUAGES="es,en,fr,de,pt,it,ru,zh,ja" # Lista de idiomas a descargar
ID_LIST_FILE="video_ids_for_download.txt" 
DOWNLOAD_ROOT="Videos" # Carpeta raíz de todas las descargas
METADATA_TEMP_FILE="metadata_temp.json" # Archivo temporal para el JSON

# --- Variables de YT-DLP ---
VIDEO_FORMAT_FILTER=""

# Colores
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Determinar el filtro de formato de video basado en el argumento de resolución
case "$RESOLUTION_ARGUMENT" in
    "SD")
        VIDEO_FORMAT_FILTER="bestvideo[height<=360][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
        ;;
    "HD")
        VIDEO_FORMAT_FILTER="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
        ;;
esac


# ----------------------------------------------------------------------------------
# 🔑 PASO A: Obtener Metadatos, Crear Carpeta, Mover JSON y Cambiar de Directorio (cd)
# ----------------------------------------------------------------------------------

echo -e "\n${YELLOW}=== Paso A: Configuración de la carpeta principal (Canal/Playlist)... ===${NC}"

# 1. Obtener el JSON de metadatos de la URL de entrada y GUARDARLO
echo -e "  Descargando JSON de metadatos de la URL principal..."
yt-dlp \
    --cookies-from-browser firefox \
    --dump-json \
    --flat-playlist \
    --no-warnings \
    "$ID_O_URL" > "$METADATA_TEMP_FILE"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERROR: No se pudo obtener el JSON de metadatos. Verifique la URL.${NC}"
    exit 1
fi

# 2. Usar jq para extraer el nombre de la playlist
RAW_NAME=$(cat "$METADATA_TEMP_FILE" | jq -r '.playlist' | head -n1)

# 3. Limpiar el nombre de Uploader/ID (Eliminar el '@' si existe, para un nombre de carpeta limpio)
UPLOADER_NAME=$(echo "$RAW_NAME" | tr -d '@')

# 4. Determinar el nombre final de la carpeta (Carpeta principal del canal/lista)
FINAL_TARGET_DIR="$DOWNLOAD_ROOT/$UPLOADER_NAME"

# 5. Crear la carpeta y mover el archivo JSON
echo -e "  Carpeta principal de destino: ${CYAN}$FINAL_TARGET_DIR${NC}"
mkdir -p "$FINAL_TARGET_DIR"

# Mover el archivo JSON guardado al directorio final
mv "$METADATA_TEMP_FILE" "$FINAL_TARGET_DIR/metadatos_base.json"
echo -e "  ${GREEN}✔ Metadatos base guardados en $FINAL_TARGET_DIR/metadatos_base.json${NC}"

# 6. Cambiar el directorio (cd) a la carpeta principal del canal/lista
if ! cd "$FINAL_TARGET_DIR"; then
    echo -e "${RED}❌ ERROR: No se pudo entrar al directorio $FINAL_TARGET_DIR.${NC}"
    exit 1
fi

echo -e "${GREEN}✔ Ubicación actual (Carpeta de canal/lista): $(pwd)${NC}"

# 6.5. Añadimos un fichero con dentro la url de la playlist y la resolución de descarga original
echo "$ID_O_URL,$RESOLUTION_ARGUMENT" > xcron


# ----------------------------------------------------------------------------------
# 🔑 PASO B: Obtener Lista de IDs
# ----------------------------------------------------------------------------------
echo -e "\n${YELLOW}=== Paso B: Obteniendo la lista de IDs de los videos... ===${NC}"
echo -e "Lista guardada en: ${CYAN}$ID_LIST_FILE${NC}"

mapfile -t VIDEO_IDS < <(yt-dlp \
    --cookies-from-browser firefox \
    --flat-playlist \
    --print id \
    --extractor-args youtube:player-client=web \
    "$ID_O_URL" | tee "$ID_LIST_FILE") 

if [ ${#VIDEO_IDS[@]} -eq 0 ]; then
    echo -e "${RED}❌ No se encontraron IDs de video. Verifique la URL y el estado de las cookies.${NC}"
    cd - > /dev/null
    exit 1
fi

TOTAL_VIDEOS=${#VIDEO_IDS[@]}
echo -e "${GREEN}✔ Encontrados $TOTAL_VIDEOS videos para procesar.${NC}"


# ----------------------------------------------------------------------------------
# 🔑 PASO C: Iteración Controlada y Descarga por ID
# ----------------------------------------------------------------------------------
PROCESSED_COUNT=0

for VIDEO_ID in "${VIDEO_IDS[@]}"; do
    PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
    
    echo -e "\n${YELLOW}===================================================================${NC}"
    echo -e "${YELLOW}🚀 Procesando Video $PROCESSED_COUNT de $TOTAL_VIDEOS: ID ${CYAN}$VIDEO_ID${NC}"
    echo -e "${YELLOW}===================================================================${NC}"

    # --- C1. CREAR Y ENTRAR EN LA SUBCARPETA DEL ID DEL VIDEO ---
    echo -e "  Creando carpeta de video: ${CYAN}$VIDEO_ID${NC}"
    mkdir -p "$VIDEO_ID"
    
    if ! cd "$VIDEO_ID"; then
        echo -e "${RED}  ❌ ERROR: No se pudo entrar al directorio del video $VIDEO_ID. Saltando.${NC}"
        continue
    fi
    echo -e "${GREEN}  ✔ Ubicación actual (Carpeta de video): $(pwd)${NC}"

    # --- C2. Pausa de cortesía entre videos ---
    RANDOM_BREAK=$(shuf -i 14-38 -n 1)
    if [ "$PROCESSED_COUNT" -gt 1 ]; then
        echo -e "  Esperando ${CYAN}$RANDOM_BREAK${NC} segundos antes de iniciar la descarga del video..."
        sleep "$RANDOM_BREAK"
    fi

    # --- C3. FASE 1: Descargar Video/Thumbnail (MP4 con filtro de resolución) ---
    echo -e "  ${CYAN}--- FASE 1/2: Descargando Video ($RESOLUTION_ARGUMENT en MP4) y Thumbnail ---${NC}"
    
    # Patrón de salida simple dentro de la carpeta: ID.ext (ej: Dts7KcHk1_k.mp4)
    VIDEO_OUTPUT_PATTERN="%(id)s.%(ext)s"

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
        -- "$VIDEO_ID"
    
    EXIT_CODE_PHASE1=$?

    if [ $EXIT_CODE_PHASE1 -ne 0 ]; then
        echo -e "${RED}  ❌ ERROR FASE 1: Fallo al descargar video ID $VIDEO_ID. Saltando subtítulos.${NC}"
        # Volver al directorio principal del canal/lista antes de continuar el bucle
        cd ..
        continue
    fi
    echo -e "  ${GREEN}✔ Descarga del video principal completada.${NC}"

    # --- C4. Pausa Obligatoria entre Fases (Aleatoria 3-8s) ---
    RANDOM_SLEEP_BREAK=$(shuf -i 27-48 -n 1)
    echo -e "  Esperando ${CYAN}$RANDOM_SLEEP_BREAK${NC} segundos antes de descargar los subtítulos...${NC}"
    sleep "$RANDOM_SLEEP_BREAK"

    # --- C5. FASE 2: Descargar Subtítulos (UNO POR UNO) ---
    echo -e "  ${CYAN}--- FASE 2/2: Descargando Subtítulos Idioma por Idioma (formato VTT) ---${NC}"
    
    LANGUAGES_ARRAY=$(echo "$SUBTITLE_LANGUAGES" | tr ',' ' ')
    SUBTITLE_SUCCESS=0
    SUBTITLE_ATTEMPTS=0
    
    # Nuevo patrón de salida de subtítulos: SOLO CÓDIGO_IDIOMA.EXT (ej: es.vtt)
    SUBTITLE_OUTPUT_PATTERN="%(language)s.%(ext)s"
    
    for LANG_CODE in $LANGUAGES_ARRAY; do
        SUBTITLE_ATTEMPTS=$((SUBTITLE_ATTEMPTS + 1))
        
        # Comando de descarga de subtítulos
        yt-dlp \
        --cookies-from-browser firefox \
        --write-sub  \
        --write-auto-sub \
        --sub-format vtt \
        --sub-lang "$LANG_CODE" \
        -o "%(id)s.%(ext)s"  \
        --skip-download  -- "$VIDEO_ID" 

        EXIT_CODE_LANG=$?
        if [ $EXIT_CODE_LANG -eq 0 ]; then
            SUBTITLE_SUCCESS=$((SUBTITLE_SUCCESS + 1))
            echo -e "  ${GREEN}    ✔ Subtítulo $LANG_CODE descargado con éxito.${NC}"
        elif [ $EXIT_CODE_LANG -ne 1 ]; then
            echo -e "${RED}  ⚠️ ADVERTENCIA: Error al descargar subtítulo $LANG_CODE (Código $EXIT_CODE_LANG).${NC}"
        fi
        
        # Pausa aleatoria entre idiomas
        if [ "$LANG_CODE" != "$(echo "$SUBTITLE_LANGUAGES" | rev | cut -d',' -f1 | rev)" ]; then
            RANDOM_PAUSE_LANG=$(shuf -i 28-47 -n 1)
            echo -e "  Esperando ${CYAN}$RANDOM_PAUSE_LANG${NC} segundos antes del siguiente idioma..."
            sleep "$RANDOM_PAUSE_LANG"
        fi
        
    done # Fin del ciclo for de subtítulos

    if [ $SUBTITLE_SUCCESS -gt 0 ]; then
        echo -e "  ${GREEN}✔ Subtítulos: $SUBTITLE_SUCCESS de $SUBTITLE_ATTEMPTS idiomas intentados se descargaron con éxito.${NC}"
    else
        echo -e "${RED}  ⚠️ ADVERTENCIA FASE 2: No se pudo descargar ningún subtítulo para ID $VIDEO_ID.${NC}"
    fi

    # --- C6. VOLVER AL DIRECTORIO PRINCIPAL DEL CANAL/LISTA ---
    cd ..
    echo -e "${GREEN}✔ Saliendo de la carpeta de video. Ubicación actual: $(pwd)${NC}"

done # Fin del ciclo for de videos

# ----------------------------------------------------------------------------------
# 🔑 PASO D: Finalización
# ----------------------------------------------------------------------------------
# Volver al directorio original antes de terminar el script
cd - > /dev/null

echo -e "\n${GREEN}===================================================================${NC}"
echo -e "${GREEN} 🎉 Proceso de descarga de $TOTAL_VIDEOS videos de la Playlist completado. ${NC}"
echo -e "${GREEN}===================================================================${NC}"

