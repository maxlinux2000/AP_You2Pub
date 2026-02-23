#!/bin/bash
# ===============================================
# 5_legacy_migrator.sh version 1
# Muestra y sanea la estructura de canales antiguos.
# ===============================================

DOWNLOAD_ROOT="$HOME/public_html/You2Pub"
ID_LIST_OLD_PATTERN="*-yt-list"
ID_LIST_NEW_FILENAME="video_ids_for_download.txt"
DOWNLOADED_LIST_FILENAME="downloaded_video_ids.txt"

# Colores
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- FUNCIONES DE SANEO ---

decode_url() {
    # Convierte secuencias hexadecimales (%E9) en caracteres reales
    printf '%b\n' "${1//%/\\x}"
}

sane_name() {
    local decoded=$(decode_url "$1")
    # Regla: Mantenemos acentos y eñes ([:alnum:]), puntos, guiones y guiones bajos.
    # El resto (espacios, caracteres chinos, emojis, símbolos) se convierte en "_"
    echo "$decoded" | sed 's/[^[:alnum:]\._-]/_/g' | tr ' ' '_'
}

# ----------------------------------------------------------------------------------
# 🔑 PASO 0: RENOMBRADO PREVENTIVO (Nivel de Canal)
# ----------------------------------------------------------------------------------
echo -e "${BLUE}🔍 Escaneando carpetas que no cumplen las reglas de nombre...${NC}"

# Recorremos primero para renombrar lo que esté "sucio"
cd $DOWNLOAD_ROOT
find . -maxdepth 1 -mindepth 1 -type d | while read -r folder; do
    folder_name=$(basename "$folder")
    # echo folder_name=$folder_name
    # Ignorar carpetas de sistema
    [[ "$folder_name" =~ ^(js|css|img|stuff)$ ]] && continue

    # Calculamos cómo debería llamarse
    target_name=$(sane_name "$folder_name")

    # Si el nombre actual no coincide con el saneado
    if [ "$folder_name" != "$target_name" ]; then
        echo -e "${YELLOW}⚠️ Nombre no cumple: '$folder_name' -> '$target_name'${NC}"
        
        # Si la carpeta de destino ya existe, movemos contenido en lugar de renombrar
        if [ -d "$DOWNLOAD_ROOT/$target_name" ]; then
            echo -e "${CYAN}  📦 El destino ya existe, fusionando contenido...${NC}"
            cp -rn "$folder"/* "$DOWNLOAD_ROOT/$target_name/" 2>/dev/null
            rm -rf "$folder"
        else
            mv "$folder" "$DOWNLOAD_ROOT/$target_name"
            echo -e "${GREEN}  ✅ Carpeta renombrada correctamente.${NC}"
        fi
    fi
done

# ----------------------------------------------------------------------------------
# 🔑 PASO 1: Migración de Archivos y Metadatos
# ----------------------------------------------------------------------------------
echo -e "\n${BLUE}🚀 Iniciando Migración de IDs y Metadatos...${NC}"

# Ahora procesamos las carpetas (que ya están saneadas del paso anterior)
find "$DOWNLOAD_ROOT" -maxdepth 1 -mindepth 1 -type d | while read -r CURRENT_CHANNEL_PATH; do
    folder_name=$(basename "$CURRENT_CHANNEL_PATH")
    [[ "$folder_name" =~ ^(js|css|img|stuff)$ ]] && continue

    echo -e "${CYAN}📂 Procesando Canal: $folder_name${NC}"

    pushd "$CURRENT_CHANNEL_PATH" > /dev/null || continue

    # 1. Limpiar Non-Breaking Spaces (\xc2\xa0) en archivos JSON
    find . -name "*.json" -exec sed -i 's/\xc2\xa0/ /g' {} +

    # 2. Migrar listas de IDs antiguas (*-yt-list) al nuevo formato
    OLD_LIST=$(find . -maxdepth 1 -name "$ID_LIST_OLD_PATTERN" | head -n 1)
    if [ -n "$OLD_LIST" ] && [ ! -f "$ID_LIST_NEW_FILENAME" ]; then
        echo -e "  📄 Migrando lista de IDs: $OLD_LIST -> $ID_LIST_NEW_FILENAME"
        cp "$OLD_LIST" "$ID_LIST_NEW_FILENAME"
        # También creamos el registro de "ya descargados" para no repetir trabajo
        cp "$OLD_LIST" "$DOWNLOADED_LIST_FILENAME"
    fi

    # 3. Lanzar generador de canal para este directorio
    if [ -f "$DOWNLOAD_ROOT/generate_channel.sh" ]; then
        bash "$DOWNLOAD_ROOT/generate_channel.sh" "."
    fi

    popd > /dev/null
done

# ----------------------------------------------------------------------------------
# 🔑 PASO FINAL: Reconstrucción Global
# ----------------------------------------------------------------------------------
echo -e "\n${GREEN}✨ Finalizando: Reconstruyendo índices del sitio...${NC}"

if [[ -f "$DOWNLOAD_ROOT/generate_menu.sh" ]]; then
    bash "$DOWNLOAD_ROOT/generate_menu.sh" "$DOWNLOAD_ROOT"
fi

if [[ -f "$DOWNLOAD_ROOT/generate_root.sh" ]]; then
    bash "$DOWNLOAD_ROOT/generate_root.sh" "$DOWNLOAD_ROOT"
fi

echo -e "${GREEN}✅ ¡MIGRACIÓN, SANEO Y ACTUALIZACIÓN COMPLETADOS!${NC}"
