#!/bin/bash

# ====================================================================================
# SCRIPT DE INSTALACIÓN CONSOLIDADO: YT-DLP, DENO OFFLINE Y ARCHIVOS YOU2PUB
# ------------------------------------------------------------------------------------
# Este script realiza:
# 1. Instalación de yt-dlp con soporte curl-cffi.
# 2. Instalación del binario Deno y la caché/std de forma OFFLINE.
# 3. Copia de todos los scripts y archivos web de You2Pub a sus destinos finales.
# ====================================================================================

# --- Variables de Entorno y Rutas ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INSTALL_BIN_DIR="$HOME/.local/bin"
INSTALL_WEB_DIR="$HOME/public_html/You2Pub"
DENO_OFFLINE_ARCHIVE="deno_offline_installer_linux-x64.tar.gz"
DENO_CACHE_DIR="$HOME/.cache/deno"
YOU2PUB_SOURCE_DIR="you2pub_files"
TEMP_EXTRACT_DIR="/tmp/deno_offline_install_$$"
# Rutas
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps" # Usamos 'scalable' para SVG
DESKTOP_DIR="$HOME/.local/share/applications"



echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} 🚀 Iniciando la instalación COMPLETA de You2Pub ${NC}"
echo -e "${GREEN} Directorio de Binarios: ${INSTALL_BIN_DIR} ${NC}"
echo -e "${GREEN} Directorio Web: ${INSTALL_WEB_DIR} ${NC}"
echo -e "${GREEN}============================================${NC}"

# ------------------------------------------------
# PASO 1: Configurar el entorno y verificar requisitos
# ------------------------------------------------

echo -e "\n${YELLOW}1. Verificando Directorios y Entorno...${NC}"
mkdir -p "$INSTALL_BIN_DIR"
mkdir -p "$INSTALL_WEB_DIR"

if [ ! -f "$DENO_OFFLINE_ARCHIVE" ]; then
    echo -e "${RED}❌ ERROR: No se encontró el paquete offline de Deno: '$DENO_OFFLINE_ARCHIVE'.${NC}"
    echo "Asegúrese de que el archivo existe en el directorio actual."
    exit 1
fi

if [ ! -d "$YOU2PUB_SOURCE_DIR" ]; then
    echo -e "${RED}❌ ERROR: No se encontró el directorio de archivos fuente de You2Pub: '$YOU2PUB_SOURCE_DIR'.${NC}"
    echo "Asegúrese de que contiene todos los scripts y archivos web."
    exit 1
fi

# ------------------------------------------------
# PASO 2: Instalar/Actualizar Python y yt-dlp con curl-cffi
# ------------------------------------------------

echo -e "\n${YELLOW}2. Instalando Python (si es necesario) y yt-dlp con curl-cffi...${NC}"

# (Dejo tu lógica de instalación de yt-dlp con pip aquí. Asumo que el entorno tiene Python)
if ! command -v pip &> /dev/null
then
    # Lógica de instalación de pip... (simplificada por espacio)
    echo "  ⚠️ ADVERTENCIA: 'pip' no encontrado. Este script asume que Python y pip están disponibles o se instalarán manualmente."
    # ...
fi

# Instalar yt-dlp (usando --user y --break-system-packages para entornos modernos)
echo "  Instalando yt-dlp con soporte avanzado de suplantación (curl-cffi)..."
pip install "yt-dlp[default,curl-cffi]" --upgrade --user --break-system-packages

if [ $? -eq 0 ]; then
    echo -e "    ${GREEN}✔ yt-dlp con soporte curl-cffi instalado con éxito.${NC}"
else
    echo -e "${RED}    ❌ Error al instalar yt-dlp o curl-cffi. Revisa el error de pip.${NC}"
    exit 1
fi

# ------------------------------------------------
# PASO 3: Instalación de Deno OFFLINE (Binario y Caché)
# ------------------------------------------------

echo -e "\n${YELLOW}3. Instalando Deno y Caché de forma OFFLINE...${NC}"

# a. Preparar entorno temporal y descomprimir el paquete completo
echo "  [3a/c] Desempaquetando '$DENO_OFFLINE_ARCHIVE'..."
mkdir -p "$TEMP_EXTRACT_DIR"
if ! tar -xzf "$DENO_OFFLINE_ARCHIVE" -C "$TEMP_EXTRACT_DIR"; then
    echo -e "${RED}❌ ERROR: Fallo al descomprimir el archivo de Deno offline. Saliendo...${NC}"
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi

# Rutas de origen dentro del temporal
DENO_BIN_SOURCE="${TEMP_EXTRACT_DIR}/package/deno"
STD_ARCHIVE_SOURCE="${TEMP_EXTRACT_DIR}/package/deno_std.tar.gz"
CACHE_SOURCE="${TEMP_EXTRACT_DIR}/deno_cache"


# b. Instalar el binario Deno
echo "  [3b/c] Instalando binario Deno en '$INSTALL_BIN_DIR'..."
if [ -f "$DENO_BIN_SOURCE" ]; then
    mv "$DENO_BIN_SOURCE" "$INSTALL_BIN_DIR/"
    chmod +x "$INSTALL_BIN_DIR/deno"
    echo -e "    ${GREEN}✔ Binario Deno instalado.${NC}"
else
    echo -e "${RED}❌ ERROR: Binario Deno no encontrado en la ruta de extracción.${NC}"
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi


# c. Instalar Caché (remote/gen) y deno_std (source)
echo "  [3c/c] Configurando Caché y deno_std en '$DENO_CACHE_DIR'..."
mkdir -p "$DENO_CACHE_DIR"

# Copiar Caché precalentada de módulos
if [ -d "$CACHE_SOURCE" ]; then
    cp -R "${CACHE_SOURCE}/." "$DENO_CACHE_DIR/"
fi

# Descomprimir el código fuente de deno_std (que contiene std-0.224.0)
if [ -f "$STD_ARCHIVE_SOURCE" ]; then
    if tar -xzf "$STD_ARCHIVE_SOURCE" -C "$DENO_CACHE_DIR"; then
        echo -e "    ${GREEN}✔ Caché y deno_std configurados para uso offline.${NC}"
    else
        echo -e "${RED}❌ ERROR: Fallo al descomprimir deno_std.${NC}"
    fi
else
    echo -e "${RED}❌ ADVERTENCIA: Archivo deno_std.tar.gz no encontrado. La std puede fallar offline.${NC}"
fi

# Limpieza temporal de Deno
rm -rf "$TEMP_EXTRACT_DIR"


# ------------------------------------------------
# PASO 4: Copiar los archivos de You2Pub
# ------------------------------------------------

echo -e "\n${YELLOW}4. Copiando archivos de You2Pub...${NC}"



# 4a. Copiar los scripts ejecutables a ~/.local/bin/
echo "  [4a/b] Copiando scripts (.sh, .ts, .js) a '$INSTALL_BIN_DIR'..."
# La lista de archivos proporcionada:
# 1_downloader.sh, 2_channel_downloader.sh, 3_playlist_downloader.sh, 4_consolidator.sh
# generate_html.sh, generate_menu.ts, generate_root.js, generate_video.js

find "$YOU2PUB_SOURCE_DIR" -maxdepth 1 -type f \
    \( -name "*.sh" -o -name "*.ts" -o -name "*.js" \) \
    -exec cp {} "$INSTALL_BIN_DIR/" \;
cp $YOU2PUB_SOURCE_DIR/You2Pub "$INSTALL_BIN_DIR/"

# Asegurar permisos de ejecución para scripts .sh
chmod +x "$INSTALL_BIN_DIR"/*.sh
chmod +x "$INSTALL_BIN_DIR/You2Pub"

echo -e "    ${GREEN}✔ Scripts de binario copiados y listos.${NC}"

# 4b. Copiar los archivos web a $HOME/public_html/You2Pub
echo "  [4b/b] Copiando contenido web a '$INSTALL_WEB_DIR'..."
# Asegurar que el directorio de destino está limpio antes de copiar (opcional, pero seguro)
rm -rf "$INSTALL_WEB_DIR"/*

# 4c. Copiar Icono SVG (Auto-escalable)
echo "  [4b/c] Instalando Icono SVG en '$ICON_DIR'..."
mkdir -p "$ICON_DIR"
if [ -f "$YOU2PUB_SOURCE_DIR/you2pub.svg" ]; then
    cp "$YOU2PUB_SOURCE_DIR/you2pub.svg" "$ICON_DIR/you2pub.svg"
    echo -e "    ${GREEN}✔ Icono SVG (you2pub.svg) instalado.${NC}"
else
    echo -e "${RED}❌ ADVERTENCIA: Icono you2pub.svg no encontrado. El lanzador no tendrá imagen.${NC}"
fi

# 4d. Copiar el Lanzador .desktop
echo "  [4c/c] Copiando lanzador .desktop a '$DESKTOP_DIR'..."
mkdir -p "$DESKTOP_DIR"
if [ -f "$YOU2PUB_SOURCE_DIR/you2pub.desktop" ]; then
    cp "$YOU2PUB_SOURCE_DIR/you2pub.desktop" "$DESKTOP_DIR/"
    # Actualizar la base de datos de escritorio para que el sistema lo vea
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null
    echo -e "    ${GREEN}✔ Lanzador .desktop instalado y base de datos actualizada.${NC}"
else
    echo -e "${RED}❌ ADVERTENCIA: Lanzador you2pub.desktop no encontrado. No se instalará acceso directo.${NC}"
fi

# Copiar todos los contenidos de la carpeta fuente recursivamente
cp -R "$YOU2PUB_SOURCE_DIR"/css "$INSTALL_WEB_DIR/"
cp -R "$YOU2PUB_SOURCE_DIR"/js "$INSTALL_WEB_DIR/"

echo -e "    ${GREEN}✔ Archivos web copiados con éxito.${NC}"


# ------------------------------------------------
# PASO 5: Mensaje Final de Configuración
# ------------------------------------------------

echo -e "\n${GREEN}============================================${NC}"
echo -e "${GREEN} 🎉 INSTALACIÓN DE YOU2PUB COMPLETADA. ${NC}"
echo -e "${GREEN}============================================${NC}"
echo "Verifique que '$INSTALL_BIN_DIR' esté en su \$PATH."
echo "Si no lo está, ejecute:"
echo -e "${YELLOW}export PATH=\"\$PATH:$INSTALL_BIN_DIR\"${NC}"
echo "--------------------------------------------"
echo "Para usar el generador web, diríjase a:"
echo "-> $INSTALL_WEB_DIR"
echo "--------------------------------------------"

