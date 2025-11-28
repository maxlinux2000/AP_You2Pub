#!/bin/bash

# ===============================================
# SCRIPT DE INSTALACIÓN LOCAL DE YT-DLP (con curl-cffi) Y DENO
# ===============================================

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/.local/bin"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} 🚀 Iniciando la instalación de yt-dlp (curl-cffi) y Deno ${NC}"
echo -e "${GREEN} Directorio de instalación: ${INSTALL_DIR} ${NC}"
echo -e "${GREEN}============================================${NC}"

# ------------------------------------------------
# PASO 1: Configurar el entorno (Directorio y PATH)
# ------------------------------------------------

echo -e "\n${YELLOW}1. Creando/Verificando el directorio de instalación...${NC}"

mkdir -p "$INSTALL_DIR"

# Simplificación del check de PATH: asume que ya lo tienes o te lo recuerda
if ! command -v yt-dlp &> /dev/null && [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${RED}⚠️ ¡ADVERTENCIA! El directorio $INSTALL_DIR no está en tu PATH.${NC}"
    echo "Para poder ejecutar 'yt-dlp' y 'deno' directamente, debes añadir la siguiente línea a tu archivo ~/.bashrc o ~/.zshrc:"
    echo -e "export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "Luego, ejecuta 'source ~/.bashrc' (o .zshrc) para aplicar los cambios."
else
    echo -e "${GREEN}   ✅ Directorio listo. PATH configurado correctamente (o se configurará).${NC}"
fi

# ------------------------------------------------
# PASO 2: Instalar/Actualizar Python y yt-dlp con curl-cffi
# ------------------------------------------------

echo -e "\n${YELLOW}2. Instalando Python (si es necesario) y yt-dlp con curl-cffi...${NC}"

# Sub-Paso 2a: Verificar e instalar pip (Python)
if ! command -v pip &> /dev/null
then
    echo "   'pip' (Gestor de paquetes de Python) no encontrado. Intentando instalarlo..."
    if command -v sudo &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y python3-pip python3-dev
        elif command -v yum &> /dev/null; then
            sudo yum install -y python3-pip python3-devel
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y python3-pip python3-devel
        else
            echo -e "${RED}   ❌ No se puede instalar 'pip' automáticamente. Instala 'python3-pip' manualmente.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}   ❌ 'pip' no está instalado y no tienes permisos de 'sudo'. Instala 'python3-pip' manualmente.${NC}"
        exit 1
    fi
fi

# Sub-Paso 2b: Instalar/Actualizar yt-dlp con el grupo de dependencias curl-cffi
echo "   Instalando yt-dlp con soporte avanzado de suplantación (curl-cffi)..."

# Usamos --break-system-packages para sistemas modernos con Python gestionado.
# Instalamos en modo usuario para evitar conflictos de sistema.
pip install "yt-dlp[default,curl-cffi]" --upgrade --user --break-system-packages

if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✅ yt-dlp con soporte curl-cffi instalado con éxito.${NC}"
else
    echo -e "${RED}   ❌ Error al instalar yt-dlp o curl-cffi. Revisa el error de pip.${NC}"
    exit 1
fi

# ------------------------------------------------
# PASO 3: Instalar/Actualizar Deno (Local)
# ------------------------------------------------

echo -e "\n${YELLOW}3. Instalando Deno localmente...${NC}"

# ... (El resto del código de Deno sigue igual ya que no requiere cambios) ...

# Detección de arquitectura del sistema
case $(uname -m) in
    x86_64) DENO_ARCH="x86_64" ;;
    arm64|aarch64) DENO_ARCH="aarch64" ;;
    *) echo -e "${RED}   ❌ Arquitectura ($(uname -m)) no soportada para la instalación automática de Deno.${NC}"; exit 1 ;;
esac

# Obtener la URL de la última versión de Deno (el binario comprimido)
DENO_LATEST_VERSION=$(curl -sL https://github.com/denoland/deno/releases/latest | grep -oP 'tag/\Kv[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$DENO_LATEST_VERSION" ]; then
    echo -e "${RED}   ❌ No se pudo obtener la última versión de Deno.${NC}"
    exit 1
fi

DENO_URL="https://github.com/denoland/deno/releases/download/$DENO_LATEST_VERSION/deno-$DENO_ARCH-unknown-linux-gnu.zip"
DENO_TEMP_DIR="$HOME/temp_deno_setup"

mkdir -p "$DENO_TEMP_DIR"
cd "$DENO_TEMP_DIR"

# Descargar el binario precompilado de Deno (viene en un ZIP)
echo "   Descargando Deno ($DENO_LATEST_VERSION - $DENO_ARCH)..."
curl -sL "$DENO_URL" -o "deno.zip"

# Requisito: instalar unzip si no está
if ! command -v unzip &> /dev/null
then
    echo "   Instalando 'unzip' temporalmente para extraer Deno..."
    if command -v sudo &> /dev/null && command -v apt-get &> /dev/null
    then
        sudo apt-get update && sudo apt-get install -y unzip
    else
        echo -e "${RED}   ❌ Error: 'unzip' no está instalado y no se puede instalar automáticamente. Instálalo manualmente.${NC}"
        exit 1
    fi
fi

# Descomprimir y mover el binario 'deno' a $INSTALL_DIR
echo "   Descomprimiendo y configurando Deno..."
unzip -o deno.zip
mv deno "$INSTALL_DIR/deno"

# Limpieza
cd "$HOME"
rm -rf "$DENO_TEMP_DIR"

if [ -f "$INSTALL_DIR/deno" ]; then
    echo -e "${GREEN}   ✅ Deno instalado y configurado con éxito.${NC}"
else
    echo -e "${RED}   ❌ Error al configurar Deno. Revisa los mensajes anteriores.${NC}"
    exit 1
fi

echo -e "\n${GREEN}============================================${NC}"
echo -e "${GREEN} 🎉 Instalación completada. ${NC}"
echo -e "${GREEN}============================================${NC}"
echo "Verifica la instalación ejecutando (después de actualizar tu PATH):"
echo "  yt-dlp --version"
echo "  deno --version"

