#!/bin/bash
# ===============================================
# LEGACY_MIGRATOR.sh
# 
# 1. RENOMBRA Y CONSOLIDA directorios de canales al ID canónico del uploader 
#    (ej. @handle) para asegurar una estructura estable. Si existe un duplicado, 
#    consolida su contenido.
# 2. Convierte los canales al nuevo formato de metadatos (video_ids_for_download.txt, 
#    channel.json, metadatos_base.json) sin descargar los videos existentes.
# ===============================================

# --- Constantes de Directorio y Archivos ---
DOWNLOAD_ROOT="$HOME/public_html/You2Pub"
ID_LIST_OLD_PATTERN="*-yt-list"
ID_LIST_NEW_FILENAME="video_ids_for_download.txt"
DOWNLOADED_LIST_FILENAME="downloaded_video_ids.txt" # Lista de IDs ya descargados/verificados
XCRON_FILENAME="xcron"

# Colores
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función de pausa segura para evitar errores 429
cuenta_atras_segura() {
    seconds=$(shuf -i 183-307 -n 1); date1=$((`date +%s` + $seconds)); 
    echo -e "  ${CYAN}Pausa de seguridad (duración: $seconds s)...${NC}"
    while [ "$date1" -ge `date +%s` ]; do 
      echo -ne "Tempo faltante: $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r"; 
      sleep 1
    done
    sleep "0.$(shuf -i 1-99 -n 1)" # Pausa decimal final
}

# ----------------------------------------------------------------------------------
# 🔑 INICIO
# ----------------------------------------------------------------------------------
START_DIR=$(pwd)

echo -e "\n${YELLOW}===================================================================${NC}"
echo -e "${YELLOW}🛠️ FASE 0: Reorganización y Consolidación de Directorios...${NC}"
echo -e "${YELLOW}===================================================================${NC}"

# -------------------------------------------------------------
# --- FASE 0: Renombrar y Consolidar Directorios (Loop 1) ---
# -------------------------------------------------------------
# Iteramos sobre todos los archivos xcron para renombrar/consolidar las carpetas

cd "$DOWNLOAD_ROOT"
find .  -type f -name "$XCRON_FILENAME" | while read -r XCRON_FILE; do
    CHANNEL_DIR=$(dirname "$XCRON_FILE")
    CHANNEL_NAME=$(basename "$CHANNEL_DIR")
    
    # Leer la URL de origen desde xcron y QUITAR el ",SD" o ",HD"
    CHANNEL_URL_FULL=$(head -n 1 "$XCRON_FILE")
    CHANNEL_URL=$(echo "$CHANNEL_URL_FULL" | cut -d ',' -f1)

    # -------------------------------------------------------------
    # --- Lógica de Extracción de ID Canónico (Mejorada) ---
    # El ID canónico es el último segmento de la ruta de la URL (después de /c/, /user/, o @).
    
    # 1. Limpiar la URL de la barra final si existe
    CLEAN_URL=$(echo "$CHANNEL_URL" | sed 's/\/$//')
    
    # 2. Extraer el segmento final (uploader ID) usando basename
    UPLOADER_ID_CANDIDATE=$(basename "$CLEAN_URL")
    
    # 3. Si el ID extraído comienza con '@', eliminarlo para obtener el ID de carpeta limpio
    if [[ "$UPLOADER_ID_CANDIDATE" == @* ]]; then
        UPLOADER_ID_CANDIDATE=${UPLOADER_ID_CANDIDATE:1}
    fi
    
    # 4. Limpieza final de espacios
    UPLOADER_ID_CANDIDATE=$(echo "$UPLOADER_ID_CANDIDATE" | tr -d '[:space:]')
    
    # -------------------------------------------------------------
    
    # Si la extracción fue exitosa y el nombre es diferente al actual del directorio
    if [ -n "$UPLOADER_ID_CANDIDATE" ] && [ "$CHANNEL_NAME" != "$UPLOADER_ID_CANDIDATE" ]; then
        NEW_CHANNEL_DIR=$(dirname "$CHANNEL_DIR")/$UPLOADER_ID_CANDIDATE
        
        echo -e "\n${CYAN}>>> COMPROBACIÓN: $CHANNEL_NAME (a $UPLOADER_ID_CANDIDATE)${NC}"

        if [ -d "$NEW_CHANNEL_DIR" ]; then
            echo -e "  ${YELLOW}⚠️ CONFLICTO DETECTADO: La carpeta '$UPLOADER_ID_CANDIDATE' ya existe. Consolidando contenido...${NC}"
            
            # Mover el contenido de la carpeta antigua a la nueva, sobrescribiendo
            # Usamos `mv` con wildcard para mover archivos y carpetas, sobrescribiendo los que tienen el mismo nombre.
            # 2>/dev/null suprime mensajes de error si encuentra subdirectorios
            mv "$CHANNEL_DIR"/* "$NEW_CHANNEL_DIR/" 2>/dev/null
            
            # Eliminar la carpeta antigua (ahora vacía o con archivos que no se movieron)
            rmdir "$CHANNEL_DIR" 2>/dev/null
            echo -e "  ${GREEN}✔ Contenido de '$CHANNEL_NAME' consolidado en '$UPLOADER_ID_CANDIDATE'.${NC}"
            
        else
            echo -e "  ${GREEN}✅ REORGANIZACIÓN: Renombrando directorio de '$CHANNEL_NAME' a '$UPLOADER_ID_CANDIDATE'.${NC}"
            
            # Mover el directorio completo
            if mv "$CHANNEL_DIR" "$NEW_CHANNEL_DIR"; then
                echo -e "  ${GREEN}✔ Directorio renombrado con éxito a $UPLOADER_ID_CANDIDATE.${NC}"
            else
                echo -e "  ${RED}❌ ERROR: Fallo al renombrar el directorio. Saltando la migración de metadatos para este canal.${NC}"
            fi
        fi
    fi
done


exit


# ----------------------------------------------------------------------------------
echo -e "\n${YELLOW}===================================================================${NC}"
echo -e "${YELLOW}🛠️ FASES 1 & 2: Migración de Metadatos (Loop 2) ${NC}"
echo -e "${YELLOW}===================================================================${NC}"
# -------------------------------------------------------------
# --- FASE 1 & 2: Migrar Metadatos (Loop 2) ---
# -------------------------------------------------------------
# Iteramos sobre la lista FINAL de archivos xcron, que ahora deben estar en directorios canónicos.

cd "$DOWNLOAD_ROOT"
find . -type f -name "$XCRON_FILENAME" | while read -r XCRON_FILE; do
    CHANNEL_DIR=$(dirname "$XCRON_FILE")
    CHANNEL_NAME=$(basename "$CHANNEL_DIR")
    
    echo -e "\n${CYAN}>>> PROCESANDO METADATOS: $CHANNEL_NAME ${NC}"

    # 1. Entrar al directorio del canal
    if ! pushd "$CHANNEL_DIR" > /dev/null; then
        echo -e "${RED}❌ ERROR: No se pudo entrar a $CHANNEL_DIR. Saltando.${NC}"
        continue
    fi
    
    # Obtener la URL del canal nuevamente (se usa cut -d ',' -f1 para QUITAR ,SD/HD)
    CHANNEL_URL_FULL=$(head -n 1 "$XCRON_FILE")
    CHANNEL_URL=$(echo "$CHANNEL_URL_FULL" | cut -d ',' -f1)
    
    if [ -z "$CHANNEL_URL" ]; then
        echo -e "${RED}❌ ERROR: URL de canal vacía en xcron. Saltando la migración de metadatos.${NC}"
        popd > /dev/null
        continue
    fi
    
    echo -e "  ${BLUE}Info: URL de origen detectada: $CHANNEL_URL${NC}"

    # --- Renombrar Archivo de Lista de IDs ---
    OLD_LIST_FILE=$(find . -maxdepth 1 -name "$ID_LIST_OLD_PATTERN" -print -quit)

    if [ -n "$OLD_LIST_FILE" ]; then
        if [ ! -f "$ID_LIST_NEW_FILENAME" ]; then
            mv "$OLD_LIST_FILE" "$ID_LIST_NEW_FILENAME"
            echo -e "  ${GREEN}✔ Lista de IDs renombrada: $OLD_LIST_FILE -> $ID_LIST_NEW_FILENAME${NC}"
            
            # --- CREAR downloaded_video_ids.txt ---
            cp "$ID_LIST_NEW_FILENAME" "$DOWNLOADED_LIST_FILENAME"
            echo -e "  ${GREEN}✔ Creado $DOWNLOADED_LIST_FILENAME para marcar todos como descargados.${NC}"
        else
            echo -e "  ${YELLOW}⚠️ $ID_LIST_NEW_FILENAME ya existe. Saltando el renombrado.${NC}"
        fi
    fi
    
    # --- Descargar channel.json ---
    if [ ! -f channel.json ]; then
        echo -e "  ${YELLOW}→ channel.json faltante. Descargando metadatos del canal...${NC}"
        cuenta_atras_segura
        
        yt-dlp \
            --cookies-from-browser firefox \
            --skip-download \
            --write-info-json \
            --playlist-items 0 \
            --output "channel_temp.%(ext)s" \
            -- "$CHANNEL_URL" 2>/dev/null

        if [ -f channel_temp.info.json ]; then
            mv channel_temp.info.json channel.json
            echo -e "  ${GREEN}✔ Metadatos de canal (channel.json) descargados.${NC}"
        else
            echo -e "  ${RED}❌ Fallo al descargar metadatos del canal.${NC}"
        fi
    else
        echo -e "  ${BLUE}✔ channel.json ya existe. Saltando la descarga.${NC}"
    fi

    # --- Descargar metadatos_base.json ---
    METADATOS_BASE_FILENAME="metadatos_base.json"
    if [ ! -f "$METADATOS_BASE_FILENAME" ]; then
        echo -e "  ${YELLOW}→ $METADATOS_BASE_FILENAME faltante. Descargando metadatos base...${NC}"
        cuenta_atras_segura
        
        yt-dlp \
            --cookies-from-browser firefox \
            --dump-json \
            --flat-playlist \
            --no-warnings \
            -- "$CHANNEL_URL" > "$METADATOS_BASE_FILENAME" 2>/dev/null

        if [ $? -eq 0 ] && [ -s "$METADATOS_BASE_FILENAME" ]; then
             echo -e "  ${GREEN}✔ Metadatos base descargados y guardados.${NC}"
        else
             echo -e "  ${RED}❌ Fallo al descargar metadatos base. (Puede ser normal para canales muy grandes).${NC}"
        fi
    else
        echo -e "  ${BLUE}✔ $METADATOS_BASE_FILENAME ya existe. Saltando la descarga.${NC}"
    fi
    
    # --- Generar Lista de IDs de respaldo si faltan ambas ---
    if [ ! -f "$ID_LIST_NEW_FILENAME" ] && [ -n "$CHANNEL_URL" ]; then
        echo -e "  ${YELLOW}→ $ID_LIST_NEW_FILENAME aún faltante. Generando lista de IDs desde la URL...${NC}"
        cuenta_atras_segura
        
        yt-dlp \
            --cookies-from-browser firefox \
            --flat-playlist \
            --no-warnings \
            --print id \
            -- "$CHANNEL_URL" > "$ID_LIST_NEW_FILENAME"
            
        if [ $? -eq 0 ] && [ -s "$ID_LIST_NEW_FILENAME" ]; then
            echo -e "  ${GREEN}✔ Lista de IDs generada con éxito.${NC}"
            cp "$ID_LIST_NEW_FILENAME" "$DOWNLOADED_LIST_FILENAME"
            echo -e "  ${GREEN}✔ Creado $DOWNLOADED_LIST_FILENAME para marcar todos como descargados.${NC}"
        else
            echo -e "  ${RED}❌ Fallo al generar la lista de IDs. No se podrá procesar el canal.${NC}"
        fi
    fi

    # 3. Salir del directorio del canal
    popd > /dev/null
    
done

# ----------------------------------------------------------------------------------
# 🔑 PASO FINAL: Limpieza y Fin
# ----------------------------------------------------------------------------------

if [ "$START_DIR" != "$(pwd)" ]; then
    echo -e "\n${CYAN}Volviendo al directorio inicial: $START_DIR...${NC}"
    cd "$START_DIR"
fi

echo -e "\n${GREEN}===================================================================${NC}"
echo -e "${GREEN} 🎉 Migración Rápida y Reorganización Finalizada.${NC}"
echo -e "${GREEN}===================================================================${NC}"