#!/bin/bash
# uninstall_you2pub.sh - Script desinstalador y recolector de You2Pub

# --- Configuración ---
# Lista de archivos y directorios a recolectar/eliminar.
# ¡Es crucial que esta lista sea precisa!
FILES_TO_MANAGE=(
    "/etc/sudoers.d/yt-dlp"
    "/usr/local/bin/CreateYTindex"
    "/usr/local/bin/phantomjs"
    "/usr/local/bin/You2Pub"
    "/usr/local/share/applications/You2Pub.desktop"
    "/usr/local/share/icons/hicolor/you2pub.png"
    "/usr/local/share/You2Pub_stuff" # Eliminará el directorio y todo su contenido
)

BACKUP_NAME="You2Pub_2.6.tgz"
BACKUP_DIR="${HOME}/You2Pub_Backups" # Directorio de destino de la copia de seguridad

# --- 1. Verificación de permisos (Debe ser root) ---
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Este script debe ejecutarse como root (usando 'sudo')."
    exit 1
fi

echo "--- Iniciando Desinstalación y Recolección de You2Pub ---"

# --- 2. Recolección/Copia de Seguridad ---
echo "💾 Creando directorio de copia de seguridad en: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

echo "⏳ Recolectando archivos instalados en $BACKUP_NAME..."

# Crear un archivo temporal con la lista de archivos *existentes*
TEMP_LIST=$(mktemp)
for item in "${FILES_TO_MANAGE[@]}"; do
    if [ -e "$item" ]; then
        echo "$item" >> "$TEMP_LIST"
    else
        echo "   (Omitiendo: $item no encontrado)"
    fi
done

# Crear el tarball solo con los archivos que existen
if [ -s "$TEMP_LIST" ]; then
    # Usamos -C / para asegurar que los paths en el tarball sean absolutos (Ej: /usr/local/bin/...)
    tar -czf "$BACKUP_DIR/$BACKUP_NAME" -T "$TEMP_LIST" -C /
    echo "✅ Copia de seguridad guardada con éxito en: $BACKUP_DIR/$BACKUP_NAME"
else
    echo "⚠️ Advertencia: No se encontraron archivos para recolectar. Se omitirá la creación del tarball de respaldo."
fi
rm "$TEMP_LIST"

# --- 3. Eliminación de archivos ---
echo "🗑️ Eliminando archivos y directorios instalados..."

# Bucle para eliminar archivos y directorios en la lista
for item in "${FILES_TO_MANAGE[@]}"; do
    if [ -e "$item" ]; then
        echo "   Eliminando: $item"
        rm -rf "$item" # Usamos rm -rf para archivos y directorios
    fi
done


echo "--- Desinstalación y Recolección completada. ---"
exit 0
