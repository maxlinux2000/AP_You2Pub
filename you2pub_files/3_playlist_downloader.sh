#!/bin/bash

# ===============================================
# 3_playlist_downloader.sh
# Gestiona la descarga de una Playlist o un Canal con estructura de Playlist.
# Fusión de lógica de descarga robusta con saneamiento de nombres.
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
    # Todo lo demás a "_" para evitar problemas en el sistema de archivos.
    echo "$decoded" | sed 's/[^[:alnum:]\._-]/_/g'
}

# Determinar el filtro de formato de video basado en el argumento de resolución
VIDEO_FORMAT_FILTER="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
case "$RESOLUTION_ARGUMENT" in
    "SD")
        VIDEO_FORMAT_FILTER="bestvideo[height<=360][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
        ;;
    "HD")
        VIDEO_FORMAT_FILTER="bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
        ;;
esac

# ----------------------------------------------------------------------------------
# 🔑 PASO A: Obtener metadatos de la Playlist y Saneamiento
# ----------------------------------------------------------------------------------

echo -e "\n${YELLOW}=== Paso A: Configuración de la carpeta (Saneamiento) ===${NC}"

# Obtenemos la info básica
PLAYLIST_RAW_INFO=$(yt-dlp --cookies-from-browser firefox --dump-json --playlist-items 1 "$ID_O_URL")

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERROR: No se pudo obtener metadatos de la playlist.${NC}"
    exit 1
fi

# Extraer título original y sanearlo para la carpeta física
PLAYLIST_TITLE_ORIGINAL=$(echo "$PLAYLIST_RAW_INFO" | jq -r '.title // .playlist_title // "Unknown_Playlist"')
PLAYLIST_NAME=$(sane_name "$PLAYLIST_TITLE_ORIGINAL")
CHANNEL_DIR="$DOWNLOAD_ROOT/$PLAYLIST_NAME"

echo -e "${GREEN}✔ Playlist identificada: $PLAYLIST_TITLE_ORIGINAL${NC}"
echo -e "${YELLOW}📂 Carpeta de destino: $CHANNEL_DIR${NC}"

mkdir -p "$CHANNEL_DIR/img"

# Guardar info y limpiar Non-Breaking Spaces (\xc2\xa0)
echo "$PLAYLIST_RAW_INFO" | sed 's/\xc2\xa0/ /g' > "$CHANNEL_DIR/channel.info.json"

# --- B. Gestión de Icono y Banner ---

# 1. Intentar descargar Icono
ICON_URL=$(echo "$PLAYLIST_RAW_INFO" | jq -r '.thumbnails[] | select(.id == "0") | .url')
# '

if [ -n "$ICON_URL" ] && [ "$ICON_URL" != "null" ]; then
    wget -q "$ICON_URL" -O "$CHANNEL_DIR/img/icon.png" 2>/dev/null
fi

# 2. Descargar y procesar Banner
BANNER_URL=$(echo "$PLAYLIST_RAW_INFO" | jq -r '.thumbnails[] | select(.id == "2").url')
# '


if [ -z "$BANNER_URL" ] || [ "$BANNER_URL" == "null" ]; then
    # Fallback si no hay ID 2
    BANNER_URL=$(echo "$PLAYLIST_RAW_INFO" | jq -r '.thumbnail')
fi

echo -e "  Descargando arte de la playlist..."
wget -q -O "$CHANNEL_DIR/img/banner_raw" "$BANNER_URL" 2>/dev/null

# Conversión de seguridad para el Banner
FILE_TYPE=$(file --mime-type -b "$CHANNEL_DIR/img/banner_raw")
case "$FILE_TYPE" in
    image/png)
        ffmpeg -i "$CHANNEL_DIR/img/banner_raw" -y "$CHANNEL_DIR/img/banner.jpg" > /dev/null 2>&1
        rm "$CHANNEL_DIR/img/banner_raw"
        ;;
    image/jpeg)
        mv "$CHANNEL_DIR/img/banner_raw" "$CHANNEL_DIR/img/banner.jpg"
        ;;
    *)
        # Si falla el tipo, intentamos yt-dlp como último recurso
        yt-dlp --cookies-from-browser firefox --write-thumbnail --skip-download --convert-thumbnails jpg \
            -o "$CHANNEL_DIR/img/banner.%(ext)s" "$ID_O_URL" --playlist-items 0 > /dev/null 2>&1
        ;;
esac

# Guardar configuración para xcron
echo "$ID_O_URL,$RESOLUTION_ARGUMENT" > "$CHANNEL_DIR/xcron"

# ----------------------------------------------------------------------------------
# 🔑 PASO B: Obtener Lista de IDs
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
    echo -e "${RED}❌ No se encontraron IDs. Saliendo.${NC}"
    exit 1
fi

echo -e "${GREEN}✔ Encontrados $TOTAL_VIDEOS videos para procesar.${NC}"

# ----------------------------------------------------------------------------------
# 🔑 PASO C: Iteración y Descarga (Lógica de 6405714.sh)
# ----------------------------------------------------------------------------------

PROCESSED_COUNT=0

for VIDEO_ID in "${VIDEO_IDS[@]}"; do
    PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
    
    echo -e "\n${YELLOW}===================================================================${NC}"
    echo -e "${YELLOW}🚀 Procesando Video $PROCESSED_COUNT de $TOTAL_VIDEOS: ID ${CYAN}$VIDEO_ID${NC}"
    echo -e "${YELLOW}===================================================================${NC}"

    mkdir -p "$VIDEO_ID"
    if ! cd "$VIDEO_ID"; then continue; fi

    # Pausa de cortesía
    if [ "$PROCESSED_COUNT" -gt 1 ]; then
        RANDOM_BREAK=$(shuf -i 15-35 -n 1)
        echo -e "  Esperando ${CYAN}$RANDOM_BREAK${NC} segundos..."
        sleep "$RANDOM_BREAK"
    fi

    # --- FASE 1: Video ---
    yt-dlp \
        --cookies-from-browser firefox \
        -f "$VIDEO_FORMAT_FILTER" \
        --recode-video mp4 \
        --write-thumbnail --convert-thumbnails jpg \
        --embed-metadata --write-info-json \
        --limit-rate 1M \
        --download-archive "../$DOWNLOAD_ARCHIVE_NAME" \
        -o "%(id)s.%(ext)s" \
        -- "$VIDEO_ID"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}  ❌ Fallo en descarga de $VIDEO_ID${NC}"
        cd ..
        continue
    fi

    # --- FASE 2: Subtítulos con detección de Error 429 ---
    LANGUAGES_ARRAY=$(echo "$SUBTITLE_LANGUAGES" | tr ',' ' ')
    for LANG_CODE in $LANGUAGES_ARRAY; do
        YTDLP_ERROR=$(yt-dlp \
            --cookies-from-browser firefox \
            --write-sub --write-auto-sub \
            --sub-format vtt --sub-lang "$LANG_CODE" \
            --skip-download -o "%(id)s.%(ext)s" \
            -- "$VIDEO_ID" 2>&1 >/dev/null)
        
        if echo "$YTDLP_ERROR" | grep -q "429"; then
            echo -e "${RED}🚨 LÍMITE 429 DETECTADO! Saltando subtítulos.${NC}"
            break
        fi
        sleep $(shuf -i 3-7 -n 1)
    done

    cd ..
done

# ----------------------------------------------------------------------------------
# 🔑 PASO D: Finalización
# ----------------------------------------------------------------------------------

if [[ -f "$HOME/public_html/You2Pub/generate_channel.sh" ]]; then
    bash "$HOME/public_html/You2Pub/generate_channel.sh" "."
fi

cd - > /dev/null
echo -e "\n${GREEN} 🎉 Proceso de la Playlist $PLAYLIST_NAME completado. ${NC}"

