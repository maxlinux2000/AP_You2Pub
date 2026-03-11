#!/bin/bash

# ===============================================
# 2_channel_downloader.sh
# Gestiona la descarga y saneo de nombres de Canal y sus videos.
# ===============================================

# --- Variables de Entrada ---
ID_O_URL="$1"
RESOLUTION_ARGUMENT="$2"

# --- Constantes ---
SUBTITLE_LANGUAGES="es,en,fr,de,pt,it,ru,zh,ja"
ID_LIST_FILE="video_ids_for_download.txt" 
DOWNLOAD_ROOT="$HOME/public_html/You2Pub"
METADATA_TEMP_FILE="metadata_temp.json"
DOWNLOAD_ARCHIVE_NAME="downloaded_video_ids.txt"

# Colores
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# --- FUNCIONES DE SANEO ---

decode_url() {
    printf '%b\n' "${1//%/\\x}"
}

sane_name() {
    local decoded=$(decode_url "$1")
    # Mantenemos letras, acentos, eñes, números, puntos y guiones.
    # Todo lo demás (incluyendo caracteres chinos o símbolos) a "_"
    echo "$decoded" | sed 's/[^[:alnum:]\._-]/_/g'
}

# Determinar el filtro de formato de video basado en el argumento de resolución
VIDEO_FORMAT_FILTER="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" # Default HD
case "$RESOLUTION_ARGUMENT" in
    "SD")
        VIDEO_FORMAT_FILTER="bestvideo[height<=360][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
        ;;
    "HD")
        VIDEO_FORMAT_FILTER="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
        ;;
esac

# ----------------------------------------------------------------------------------
# 🔑 PASO A: Obtener metadatos del canal y Saneamiento
# ----------------------------------------------------------------------------------

echo -e "${CYAN}Extrayendo información del canal...${NC}"

# Obtenemos info básica para el nombre de la carpeta
CHANNEL_RAW_INFO=$(yt-dlp --cookies-from-browser firefox --dump-json --playlist-items 1 "$ID_O_URL")

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERROR: No se pudo obtener la información del canal.${NC}"
    exit 1
fi

# Extraer nombre original (uploader o canal)
CHANNEL_NAME_ORIGINAL=$(echo "$CHANNEL_RAW_INFO" | jq -r '.channel // .uploader // .playlist_uploader_id // "Unknown_Channel"')

# Sanear el nombre para la carpeta (evita caracteres extraños en el path)
CHANNEL_NAME=$(sane_name "$CHANNEL_NAME_ORIGINAL")
CHANNEL_DIR="$DOWNLOAD_ROOT/$CHANNEL_NAME"

echo -e "${GREEN}✔ Canal identificado: $CHANNEL_NAME_ORIGINAL${NC}"
echo -e "${YELLOW}📂 Carpeta de destino: $CHANNEL_DIR${NC}"

mkdir -p "$CHANNEL_DIR/img"

# Guardar info del canal y limpiar Non-Breaking Spaces (\xc2\xa0)
echo "$CHANNEL_RAW_INFO" | sed 's/\xc2\xa0/ /g' > "$CHANNEL_DIR/channel.info.json"

# --- B. Descarga de Icono y Banner ---
echo -e "${CYAN}Descargando arte del canal (Banner e Icono)...${NC}"

# Descarga de Banner
yt-dlp --cookies-from-browser firefox --write-thumbnail --skip-download --convert-thumbnails jpg \
    -o "$CHANNEL_DIR/img/banner.%(ext)s" "$ID_O_URL" --playlist-items 0 > /dev/null 2>&1

# Descarga de Icono (Avatar)
ICON_URL=$(echo "$CHANNEL_RAW_INFO" | jq -r '.thumbnails[] | select(.id == "avatar_uncropped") | .url')

#'

if [ -n "$ICON_URL" ] && [ "$ICON_URL" != "null" ]; then
    wget -q "$ICON_URL" -O "$CHANNEL_DIR/img/icon.png"
fi

# Guardar configuración para xcron
echo "$ID_O_URL,$RESOLUTION_ARGUMENT" > "$CHANNEL_DIR/xcron"

# ----------------------------------------------------------------------------------
# 🔑 PASO B: Obtener Lista de IDs de Videos
# ----------------------------------------------------------------------------------

cd "$CHANNEL_DIR" || exit

echo -e "\n${YELLOW}=== Paso B: Obteniendo la lista de IDs de los videos... ===${NC}"

mapfile -t VIDEO_IDS < <(yt-dlp \
    --cookies-from-browser firefox \
    --flat-playlist \
    --print id \
    --extractor-args youtube:player-client=web \
    "$ID_O_URL" | tee "$ID_LIST_FILE") 

TOTAL_VIDEOS=${#VIDEO_IDS[@]}

if [ "$TOTAL_VIDEOS" -eq 0 ]; then
    echo -e "${RED}❌ No se encontraron videos para descargar.${NC}"
    exit 1
fi

echo -e "${GREEN}✔ Encontrados $TOTAL_VIDEOS videos para procesar.${NC}"

# ----------------------------------------------------------------------------------
# 🔑 PASO C: Procesar Videos (Loop de Descarga)
# ----------------------------------------------------------------------------------

PROCESSED_COUNT=0

for VIDEO_ID in "${VIDEO_IDS[@]}"; do
    PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
    
    echo -e "\n${YELLOW}===================================================================${NC}"
    echo -e "${YELLOW}🚀 Procesando Video $PROCESSED_COUNT de $TOTAL_VIDEOS: ID ${CYAN}$VIDEO_ID${NC}"
    echo -e "${YELLOW}===================================================================${NC}"

    # Crear subcarpeta del video
    mkdir -p "$VIDEO_ID"
    if ! cd "$VIDEO_ID"; then continue; fi

    # Pausa de cortesía entre videos
    if [ "$PROCESSED_COUNT" -gt 1 ]; then
        RANDOM_BREAK=$(shuf -i 15-30 -n 1)
        echo -e "  Esperando ${CYAN}$RANDOM_BREAK${NC} segundos para evitar bloqueos..."
        sleep "$RANDOM_BREAK"
    fi

    # --- FASE 1: Descargar Video ---
    echo -e "  ${CYAN}--- FASE 1/2: Descargando Video y Metadatos ---${NC}"
    
    yt-dlp \
        --cookies-from-browser firefox \
        -f "$VIDEO_FORMAT_FILTER" \
        --recode-video mp4 \
        --write-thumbnail --convert-thumbnails jpg \
        --embed-metadata \
        --write-info-json \
        --limit-rate 1M \
        --download-archive "../$DOWNLOAD_ARCHIVE_NAME" \
        --restrict-filenames \
        -o "%(id)s.%(ext)s" \
        -- "$VIDEO_ID"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}  ❌ ERROR: Fallo en la descarga del video $VIDEO_ID.${NC}"
        cd ..
        continue
    fi

    # --- FASE 2: Descargar Subtítulos (Uno a Uno) ---
    echo -e "  ${CYAN}--- FASE 2/2: Descargando Subtítulos ---${NC}"
    
    LANGUAGES_ARRAY=$(echo "$SUBTITLE_LANGUAGES" | tr ',' ' ')
    
    for LANG_CODE in $LANGUAGES_ARRAY; do
        YTDLP_ERROR=$(yt-dlp \
            --cookies-from-browser firefox \
            --write-sub --write-auto-sub \
            --sub-format vtt --sub-lang "$LANG_CODE" \
            --skip-download \
            -o "%(id)s.%(ext)s" \
            -- "$VIDEO_ID" 2>&1 >/dev/null)
        
        # Check Error 429
        if echo "$YTDLP_ERROR" | grep -q "429"; then
            echo -e "${RED}  🚨 LÍMITE 429 DETECTADO! Saltando subtítulos restantes.${NC}"
            break
        fi

        # Pausa corta entre idiomas
        sleep $(shuf -i 2-5 -n 1)
    done

    cd .. # Volver a la carpeta del canal
done

# ----------------------------------------------------------------------------------
# 🔑 PASO D: Finalización y Generación de Web
# ----------------------------------------------------------------------------------

echo -e "\n${CYAN}Generando archivos de visualización...${NC}"
if [[ -f "$HOME/public_html/You2Pub/generate_channel.sh" ]]; then
    bash "$HOME/public_html/You2Pub/generate_channel.sh" "."
fi

echo -e "\n${GREEN} 🎉 Proceso del Canal $CHANNEL_NAME completado con éxito. ${NC}"

