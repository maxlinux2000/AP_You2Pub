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
DOWNLOAD_ROOT="$HOME/public_html/You2Pub" # Carpeta raíz de todas las descargas
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

######################################
# Saneador Titulos Playlist
######################################
sanear_string() {
    local string_original="$1"
    
    # 1. Limpieza Previa (Eliminar caracteres de control)
    local string_intermedia_1
    string_intermedia_1=$(echo "$string_original" | tr -d '\000-\011\013\014\016-\037')
    
    # 2. Normalización (NBSP y asegurar UTF-8)
    local string_intermedia_3
    # 2A. Reemplazar Non-Breaking Space por espacio normal
    string_intermedia_3=$(echo "$string_intermedia_1" | sed 's/\xc2\xa0/ /g')
    # 2B. Asegurar codificación UTF-8
    string_intermedia_3=$(echo "$string_intermedia_3" | iconv -t UTF-8 -f UTF-8 -c)
    
    # 3. Escapado Final (Seguridad Bash)
    local string_saneada
    string_saneada=$(printf '%q' "$string_intermedia_3")
    
    echo "$string_saneada"
}




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
RAW_NAME=$(cat "$METADATA_TEMP_FILE" | jq -r '.playlist' | head -n1 | sed 's| |_|g')

# 3. Limpiar el nombre de Uploader/ID (Eliminar el '@' si existe, para un nombre de carpeta limpio)
UPLOADER_NAME=$(sanear_string "$RAW_NAME")

echo UPLOADER_NAME=$UPLOADER_NAME

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

# 6.1. Descargamos channel.info.json para obtener la descripcion del canal icono y banner

yt-dlp \
    --cookies-from-browser  firefox  \
    --skip-download \
    --write-info-json \
    --playlist-items 0 \
    "$ID_O_URL" \
    -o channel.json

# 6.2. Bajamos el icono del canal
mkdir -p img
#IconUrl=$(jq '.thumbnails' metadatos_base.json  | grep "url" | cut -d '"' -f4 | tail -n1 )
IconUrl=$(jq -r '.thumbnails[] | select(.id == "0") | .url' channel.info.json) #'

wget "$IconUrl" -O ./img/icon.png 2>/dev/null


# 6.3. Bajamos el banner del canal
BANNER_URL=$(jq -r '.thumbnails[] | select(.id == "2").url' channel.info.json) #'
# Define el nombre de archivo usando el nombre de usuario
#CLEAN_NAME=$(echo "$ID_O_URL" | cut -d '@' -f2)
#OUTPUT_FILENAME="banner_${CLEAN_NAME}.jpg"
#echo OUTPUT_FILENAME=$OUTPUT_FILENAME

echo "✔ URL del Banner encontrada.BANNER_URL=$BANNER_URL -  Descargando..."
# 6.3. Descargar la imagen
wget -O ./img/banner "$BANNER_URL" 2>/dev/null

FILE_TYPE=$(file --mime-type -b ./img/banner)
echo "Archivo detectado: $INPUT_FILE"
echo "Tipo MIME detectado: $FILE_TYPE"

## ⚙️ Paso 2: Convertir o Renombrar

case "$FILE_TYPE" in
    image/png)
        echo "Tipo detectado: PNG. Convirtiendo a JPEG..."
        # Usamos ffmpeg para la conversión. 
        # La bandera -y sobrescribe el archivo de salida si existe.
        ffmpeg -i ./img/banner -y ./img/banner.jpg
        if [ $? -eq 0 ]; then
            echo "✅ Conversión a ./img/banner.jpg completada."
            # Opcional: Eliminar el archivo original sin extensión
            # rm "$INPUT_FILE" 
        else
            echo "❌ Error durante la conversión con ffmpeg."
            exit 2
        fi
        ;;

    image/jpeg)
        echo "Tipo detectado: JPEG/JPG. Renombrando..."
        mv ./img/banner ./img/banner.jpg
        if [ $? -eq 0 ]; then
            echo "✅ Archivo renombrado a  ./img/banner.jpg"
        else
            echo "❌ Error al renombrar el archivo."
            exit 3
        fi
        ;;

    *)
        echo "⚠️ Advertencia: Tipo de archivo no compatible o desconocido: $FILE_TYPE. No se realizaron cambios."
        echo "Archivos compatibles: image/png, image/jpeg."
        exit 4
        ;;
esac


# 6.4 checks
if [ $? -eq 0 ] && [ -s ./img/banner.jpg ]; then
    echo "✔ Banner guardado con éxito como: img/banner.jpg."
else
    echo "❌ ERROR: Fallo al descargar el archivo."
fi

exit


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
    
# Patrón de salida: ID.ext (ej: Dts7KcHk1_k.es.vtt)

    for LANG_CODE in $LANGUAGES_ARRAY; do
        SUBTITLE_ATTEMPTS=$((SUBTITLE_ATTEMPTS + 1))
    
        # 1. Ejecutar yt-dlp y CAPTURAR LA SALIDA DE ERROR (stderr) en YTDLP_ERROR
        # 2>&1 redirige stderr a stdout, y la subshell $(...) captura todo.
        YTDLP_ERROR=$(yt-dlp \
        --cookies-from-browser firefox \
        --write-sub  \
        --write-auto-sub \
        --sub-format vtt \
        --sub-lang "$LANG_CODE" \
        -o "%(id)s.%(ext)s"  \
        --skip-download  -- "$VIDEO_ID" 2>&1 >/dev/null) # Redirige salida normal a /dev/null
    
        EXIT_CODE_LANG=$? # Capturamos el código de salida

        # 2. COMPROBACIÓN CRÍTICA DEL ERROR 429
        if echo "$YTDLP_ERROR" | grep -q "429"; then
            echo -e "${RED}🚨 LÍMITE 429 DETECTADO! Se detiene la descarga de subtítulos para el video actual.${NC}"
            break # 🛑 ¡SALIR DEL BUCLE DE IDIOMAS!
        fi
    
        # 3. COMPROBACIÓN DE ÉXITO (Lógica original)
        if [ $EXIT_CODE_LANG -eq 0 ]; then
            SUBTITLE_SUCCESS=$((SUBTITLE_SUCCESS + 1))
            echo -e "  ${GREEN}    ✔ Subtítulo $LANG_CODE descargado con éxito.${NC}"
        elif [ $EXIT_CODE_LANG -ne 1 ]; then
            echo -e "${RED}  ⚠️ ADVERTENCIA: Error al descargar subtítulo $LANG_CODE (Código $EXIT_CODE_LANG).${NC}"
        fi
    
        # Pausa aleatoria entre idiomas
        # Si no se detectó el 429, continuamos con la pausa normal
        if [ "$LANG_CODE" != "$(echo "$SUBTITLE_LANGUAGES" | rev | cut -d',' -f1 | rev)" ]; then
            RANDOM_PAUSE_LANG=$(shuf -i 32-57 -n 1)
            echo -e "  Esperando ${CYAN}$RANDOM_PAUSE_LANG${NC} segundos antes del siguiente idioma..."
            sleep "$RANDOM_PAUSE_LANG"
        fi
    
    done # Fin del ciclo for de subtítulos

    if [ $SUBTITLE_SUCCESS -gt 0 ]; then
        echo -e "  ${GREEN}✔ Subtítulos: $SUBTITLE_SUCCESS de $SUBTITLE_ATTEMPTS idiomas intentados se descargaron con éxito.${NC}"
    else
        # Aquí ya no hay necesidad de un mensaje de advertencia 429 específico,
        # porque ya lo reportamos justo al detectarlo.
        echo -e "${RED}  ⚠️ ADVERTENCIA FASE 2: No se pudo descargar ningún subtítulo para ID $VIDEO_ID.${NC}"
    fi



    # --- C6. VOLVER AL DIRECTORIO PRINCIPAL DEL CANAL ---
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

