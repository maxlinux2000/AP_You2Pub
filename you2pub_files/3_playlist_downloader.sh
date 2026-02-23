#!/bin/bash

# ===============================================
# 3_playlist_downloader.sh
# Gestiona la descarga de una Playlist o un Canal con estructura de Playlist.
# ===============================================

ID_O_URL="$1"
RESOLUTION_ARGUMENT="$2"

# --- Constantes ---
SUBTITLE_LANGUAGES="es,en,fr,de,pt,it,ru,zh,ja"
ID_LIST_FILE="video_ids_for_download.txt" 
DOWNLOAD_ROOT="$HOME/public_html/You2Pub"
METADATA_TEMP_FILE="metadata_temp.json"

# Colores
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# --- FUNCIONES DE SANEO (NUEVO) ---

decode_url() {
    # Convierte secuencias tipo %E9 en caracteres reales
    printf '%b\n' "${1//%/\\x}"
}

sane_name() {
    local decoded=$(decode_url "$1")
    # Mantenemos letras, acentos, eñes, números, puntos y guiones.
    # Convertimos todo lo demás (caracteres chinos, símbolos, espacios) en "_"
    echo "$decoded" | sed 's/[^[:alnum:]\._-]/_/g'
}

# ----------------------------------------------------------------------------------
# 🔑 PASO A: Obtener metadatos de la Playlist y Saneamiento
# ----------------------------------------------------------------------------------

echo -e "${CYAN}Extrayendo información de la playlist...${NC}"
# Obtenemos la info básica (título de la playlist)
PLAYLIST_RAW_INFO=$(yt-dlp --dump-json --playlist-items 0 "$ID_O_URL")

# Extraer título original
PLAYLIST_TITLE_ORIGINAL=$(echo "$PLAYLIST_RAW_INFO" | jq -r '.title // .playlist_title // "Unknown_Playlist"')

# Sanear el nombre para crear la carpeta física
PLAYLIST_NAME=$(sane_name "$PLAYLIST_TITLE_ORIGINAL")
CHANNEL_DIR="$DOWNLOAD_ROOT/$PLAYLIST_NAME"

echo -e "${GREEN}✔ Playlist identificada: $PLAYLIST_TITLE_ORIGINAL${NC}"
echo -e "${YELLOW}📂 Carpeta de destino saneada: $CHANNEL_DIR${NC}"

mkdir -p "$CHANNEL_DIR/img"

# Guardar info y limpiar Non-Breaking Spaces (\xc2\xa0) según tus instrucciones
echo "$PLAYLIST_RAW_INFO" | sed 's/\xc2\xa0/ /g' > "$CHANNEL_DIR/channel.info.json"

# --- B. Descarga de Miniatura de la Playlist (Banner) ---
yt-dlp --write-thumbnail --skip-download --convert-thumbnails jpg -o "$CHANNEL_DIR/img/banner.%(ext)s" "$ID_O_URL" --playlist-items 0 > /dev/null 2>&1

# ----------------------------------------------------------------------------------
# 🔑 PASO C: Procesar Videos de la Playlist
# ----------------------------------------------------------------------------------

cd "$CHANNEL_DIR" || exit

# (El resto del script sigue tu lógica original de descarga de IDs y videos)

echo -e "${GREEN}Iniciando descarga de videos en la carpeta saneada...${NC}"

# ... (Aquí continúa el bucle 'for VIDEO_ID in ...' de tu script original) ...

# Al final, ejecutar el generador de canal para esta playlist
if [[ -f "$HOME/public_html/You2Pub/generate_channel.sh" ]]; then
    bash "$HOME/public_html/You2Pub/generate_channel.sh" "."
fi

# Volver al directorio original
cd - > /dev/null

echo -e "\n${GREEN} 🎉 Proceso de la Playlist $PLAYLIST_NAME completado. ${NC}"
