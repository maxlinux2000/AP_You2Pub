#!/bin/bash

# ===============================================
# SCRIPT DE PROCESAMIENTO: generate_html.sh
# Genera las páginas HTML y convierte miniaturas a JPG usando scripts modulares.
# ===============================================


# --- Rutas de Scripts ---
BIN_DIR="$HOME/.local/bin"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ROOT_DIR="$HOME/public_html/You2Pub"
# Nombres de los scripts JS modulares
JS_ROOT="$BIN_DIR/generate_root.js" 
JS_CHANNEL="$BIN_DIR/generate_channel.js"
JS_VIDEO="$BIN_DIR/generate_video.js"

# 🛑 AÑADIR/MODIFICAR: Lista de carpetas que no son canales
CHANNEL_EXCLUDES=("css" "js" "stuff" "img") # Añade cualquier otra que sea utilidad


# 🛑 AÑADIR/VERIFICAR ESTE PASO AQUÍ
# 0.5. Generar Datos del Menú (Crea ~/public_html/You2Pub/js/menu_data.js)
echo "0.5. Generando datos del Menú ($ROOT_DIR/js/menu_data.js)..."
deno run --allow-read --allow-write $BIN_DIR/generate_menu.ts "$ROOT_DIR"
if [ $? -ne 0 ]; then
    echo -e "\n${RED}❌ Error al generar datos de menú. Abortando.${NC}"
    exit 1
fi
# 


# --- 0. Generación de CSS Global ---
echo -e "${YELLOW}0. Generando archivo CSS global (${ROOT_DIR}/css/style.css)...${NC}"
deno run --allow-write $BIN_DIR/generate_css.js "$ROOT_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}   ❌ Error al generar CSS global.${NC}"
fi

# --- 1. Generación de Archivo Raíz (Videos/index.html) ---
echo -e "${YELLOW}1. Generando el índice Raíz (${ROOT_DIR}/index.html)...${NC}"
deno run --allow-read --allow-write "$JS_ROOT" "$ROOT_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}   ❌ Error al generar índice raíz.${NC}"
fi

# --- 2. Iteración sobre cada Canal (MODIFICADO) ---
find "$ROOT_DIR" -maxdepth 1 -mindepth 1 -type d | while read -r CHANNEL_DIR; do
    CHANNEL_NAME=$(basename "$CHANNEL_DIR")

    # 🛑 FILTRO PARA CARPETAS DE UTILIDADES
    SKIP_CHANNEL=false
    for EXCL in "${CHANNEL_EXCLUDES[@]}"; do
        if [ "$CHANNEL_NAME" = "$EXCL" ]; then
            SKIP_CHANNEL=true
            echo -e "--- ⏭️ Saltando directorio de utilidades: ${CHANNEL_NAME} ---"
            break
        fi
    done

    if $SKIP_CHANNEL; then
        continue # Ir al siguiente elemento del bucle
    fi
    # 🛑 FIN DEL FILTRO
    
    echo -e "\n${YELLOW}--- Procesando Canal: ${CHANNEL_NAME} ---${NC}"
    # --- 2a. Conversión de Miniaturas y Generación de Archivos a Nivel Video ---
    echo -e "2a. Procesando videos en ${CHANNEL_NAME}...${NC}"
    find "$CHANNEL_DIR" -maxdepth 1 -mindepth 1 -type d | while read -r VIDEO_DIR; do
        if [ -f "$VIDEO_DIR"/*.info.json ]; then
            
            # --- 🔥 PASO DE MANEJO CONDICIONAL DE IMAGEN 🔥
            
            # 1. Buscar el archivo de miniatura (JPG, WEBP o PNG)
            THUMB_FILE=$(find "$VIDEO_DIR" -maxdepth 1 -type f \( -iname "*.webp" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | head -n 1)
            
            if [ -n "$THUMB_FILE" ]; then
                FILENAME_BASE=$(basename "$VIDEO_DIR")
                OUTPUT_JPG="$VIDEO_DIR/${FILENAME_BASE}.jpg"
                THUMB_EXT=${THUMB_FILE##*.}
                THUMB_EXT_LOWER=$(echo "$THUMB_EXT" | tr '[:upper:]' '[:lower:]') # Convertir a minúsculas
                
                CONVERSION_NEEDED=false

                # Si el archivo ya es JPG y tiene el nombre de salida correcto, no hacer nada.
                if [[ "$THUMB_EXT_LOWER" == "jpg" || "$THUMB_EXT_LOWER" == "jpeg" ]]; then
                    if [ "$THUMB_FILE" != "$OUTPUT_JPG" ]; then
                        # Si es JPG pero tiene otro nombre, lo copiamos para normalizar.
                        echo "   🖼️ Normalizando nombre JPG..."
                        cp -f "$THUMB_FILE" "$OUTPUT_JPG"
                    fi
                # Si es PNG o WEBP, necesitamos convertir.
                elif [[ "$THUMB_EXT_LOWER" == "png" || "$THUMB_EXT_LOWER" == "webp" ]]; then
                    CONVERSION_NEEDED=true
                fi
                
                # Ejecutar la conversión si es necesaria y el archivo de salida JPG no existe
                if $CONVERSION_NEEDED || [ ! -f "$OUTPUT_JPG" ]; then
                    
                    if [ "$THUMB_EXT_LOWER" == "webp" ]; then
                        echo "   🖼️ Convirtiendo WEBP a JPG (usando -frames:v 1)..."
                        # WEBP: Necesita -frames:v 1 para asegurar que es una sola imagen estática.
                        ffmpeg -i "$THUMB_FILE" -y -frames:v 1 -q:v 2 "$OUTPUT_JPG" >/dev/null 2>&1
                    elif [ "$THUMB_EXT_LOWER" == "png" ]; then
                        echo "   🖼️ Convirtiendo PNG a JPG..."
                        # PNG: Conversión directa, más eficiente.
                        ffmpeg -i "$THUMB_FILE" -y -q:v 2 "$OUTPUT_JPG" >/dev/null 2>&1
                    fi
                    
                    if [ $? -ne 0 ]; then
                        echo -e "${RED}   ❌ Error de ffmpeg al convertir $(basename "$THUMB_FILE"). Usando original (si es JPG).${NC}"
                    else
                        echo -e "   ${GREEN}✔ Conversión a JPG completada.${NC}"
                    fi
                fi
                
            else
                echo "   ⚠️ Advertencia: No se encontró miniatura para $VIDEO_DIR"
            fi
            
            # --- FIN DEL MANEJO CONDICIONAL ---

            # 2. Generar la página HTML
            deno run --allow-read --allow-write "$JS_VIDEO" "$VIDEO_DIR"
        fi
    done
    
    # --- 2b. Generación de Archivo Índice de Canal ---
    echo -e "2b. Generando el índice del Canal (${CHANNEL_DIR}/index.html)...${NC}"
    deno run --allow-read --allow-write "$JS_CHANNEL" "$CHANNEL_DIR"

done

# --- 3. Finalización ---
echo -e "\n${GREEN}============================================${NC}"
echo -e "${GREEN} 🎉 Proceso de generación y conversión completado. ${NC}"
echo -e "${GREEN}============================================${NC}"
