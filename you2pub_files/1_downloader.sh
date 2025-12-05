#!/bin/bash

# ===============================================
# 1_downloader.sh
# Punto de entrada principal. Dirige la ejecución a channel_downloader.sh 
# o playlist_downloader.sh según la URL proporcionada.
# Uso: ./1_downloader.sh "URL_DE_YOUTUBE" [SD|HD]
# ===============================================

# --- Variables de Entrada ---
ID_O_URL="$1"
RESOLUTION_ARGUMENT="$2"

if [ -z $RESOLUTION_ARGUMENT ]; then
    ID_O_URL=$(echo $ID_O_URL | cut -d ',' -f1)
    RESOLUTION_ARGUMENT=$(echo $ID_O_URL | cut -d ',' -f2)
fi

# Colores
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- 1. Validación de Argumentos ---
if [ -z "$ID_O_URL" ] || [ -z "$RESOLUTION_ARGUMENT" ]; then
    echo -e "${RED}❌ ERROR: Faltan argumentos.${NC}"
    echo -e "${YELLOW}Uso: $0 \"URL_DE_YOUTUBE\" [SD|HD]${NC}"
    echo -e "${YELLOW}Ejemplo: $0 \"https://youtube.com/playlist?list=XXX\" HD${NC}"
    exit 1
fi

# --- 2. Validación de Resolución ---
RESOLUTION_ARGUMENT_UPPER=$(echo "$RESOLUTION_ARGUMENT" | tr '[:lower:]' '[:upper:]')
case "$RESOLUTION_ARGUMENT_UPPER" in
    "SD"|"HD")
        echo -e "${CYAN}Resolución seleccionada: $RESOLUTION_ARGUMENT_UPPER${NC}"
        ;;
    *)
        echo -e "${RED}❌ ERROR: Resolución inválida. Solo se admiten SD o HD.${NC}"
        exit 1
        ;;
esac

# --- 3. Detección de URL y Redirección ---

# Detectar URL de Playlist: contiene 'list='
if echo "$ID_O_URL" | grep -q "list="; then
    echo -e "\n${YELLOW}▶️ DETECTADO: Playlist. Redirigiendo a 3_playlist_downloader.sh${NC}"
    # Ejecutar el script de Playlist, pasando los argumentos
    3_playlist_downloader.sh "$ID_O_URL" "$RESOLUTION_ARGUMENT_UPPER"

# Detectar URL de Canal/Usuario: contiene '@' o '/user/' o '/c/' o '/channel/'
elif echo "$ID_O_URL" | grep -E -q "(@|/user/|/c/|/channel/)"; then
    echo -e "\n${YELLOW}▶️ DETECTADO: Canal. Redirigiendo a 2_channel_downloader.sh (Pendiente de implementación)${NC}"
    # Ejecutar el script de Canal (asumiendo que existe, aunque aún no lo hemos definido)
     2_channel_downloader.sh "$ID_O_URL" "$RESOLUTION_ARGUMENT_UPPER"
#    echo -e "${RED}⚠️ La descarga de Canales aún no está implementada.${NC}"
#    exit 1

# Si no es un canal ni una playlist, podría ser un video individual (no gestionado) o una URL simple.
else
    echo -e "\n${RED}❌ ERROR: URL no reconocida como Playlist o Canal.${NC}"
    echo "URL: $ID_O_URL"
    exit 1
fi

# El código de salida del script llamado será el código de salida de 1_downloader.sh
exit $?

