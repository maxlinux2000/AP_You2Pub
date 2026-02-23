#!/bin/bash

# ===============================================
# 2_channel_downloader.sh
# Gestiona la descarga y saneo de nombres de Canal.
# ===============================================

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

# ----------------------------------------------------------------------------------
# 🔑 PASO A: Obtener metadatos del canal y Saneamiento
# ----------------------------------------------------------------------------------

echo -e "${CYAN}Extrayendo información del canal...${NC}"
CHANNEL_RAW_INFO=$(yt-dlp --dump-json --playlist-items 0 "$ID_O_URL")

# Extraer nombre original (puede venir con acentos o caracteres chinos)
CHANNEL_NAME_ORIGINAL=$(echo "$CHANNEL_RAW_INFO" | jq -r '.channel // .uploader // "Unknown_Channel"')

# Sanear el nombre para la carpeta
CHANNEL_NAME=$(sane_name "$CHANNEL_NAME_ORIGINAL")
CHANNEL_DIR="$DOWNLOAD_ROOT/$CHANNEL_NAME"

echo -e "${GREEN}✔ Canal identificado: $CHANNEL_NAME_ORIGINAL${NC}"
echo -e "${YELLOW}📂 Carpeta de destino: $CHANNEL_DIR${NC}"

mkdir -p "$CHANNEL_DIR/img"

# Guardar info del canal y limpiar Non-Breaking Spaces
echo "$CHANNEL_RAW_INFO" | sed 's/\xc2\xa0/ /g' > "$CHANNEL_DIR/channel.info.json"

# --- B. Descarga de Icono y Banner ---
# (Mantenemos tu lógica de imágenes pero asegurando la ruta saneada)
yt-dlp --write-thumbnail --skip-download --convert-thumbnails jpg -o "$CHANNEL_DIR/img/banner.%(ext)s" "$ID_O_URL" --playlist-items 0 > /dev/null 2>&1

# ----------------------------------------------------------------------------------
# 🔑 PASO C: Procesar Videos
# ----------------------------------------------------------------------------------

cd "$CHANNEL_DIR" || exit

# (Aquí vendría el resto de tu lógica de descarga de videos)
# Cuando descargues los videos, asegúrate de usar:
# yt-dlp --restrict-filenames ...
# para que los nombres de los archivos de video también sean seguros.

echo -e "${GREEN}Iniciando procesamiento de videos en $CHANNEL_NAME...${NC}"

# ... (Resto del código original del loop de videos) ...

# Al final, recuerda ejecutar el generador de canal
if [[ -f "$HOME/public_html/You2Pub/generate_channel.sh" ]]; then
    bash "$HOME/public_html/You2Pub/generate_channel.sh" "."
fi

echo -e "${GREEN} 🎉 Proceso del Canal $CHANNEL_NAME completado. ${NC}"

