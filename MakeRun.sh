#!/bin/bash
# MakeRun.sh - Script para crear un paquete autoextraíble .run

# --- Configuración ---
SOURCE_DIR="you2pub_files"
SETUP_SCRIPT="setup_you2pub.sh"
OUTPUT_DIR="You2Pub_Releases"
BASE_NAME="You2Pub"
INSTALLER_TEMPLATE="installer_template.sh"
ARCHIVE_NAME="you2pub_payload.tar.gz"

# --- 1. Verificación de archivos necesarios ---
if [ ! -d "$SOURCE_DIR" ] || [ ! -f "$SETUP_SCRIPT" ]; then
    echo "❌ Error: Asegúrate de que los archivos/directorios existen:"
    echo "  - Directorio de archivos: $SOURCE_DIR"
    echo "  - Script de instalación: $SETUP_SCRIPT"
    exit 1
fi

# --- 2. Preparar el directorio de salida ---
mkdir -p "$OUTPUT_DIR"

# --- 3. Crear el Tarball con los archivos ---
echo "📦 Creando el tarball: $ARCHIVE_NAME..."
# Empaquetar la carpeta de archivos y el script de instalación
tar -czf "$ARCHIVE_NAME" "$SOURCE_DIR" "$SETUP_SCRIPT"
if [ $? -ne 0 ]; then
    echo "❌ Error al crear el tarball."
    exit 1
fi

# --- 4. Generar el nombre de archivo con timestamp ---
TIMESTAMP=$(date +%Y%m%d_%H%M)
FINAL_RUN_FILE="$OUTPUT_DIR/${BASE_NAME}_${TIMESTAMP}.run"
echo "🕒 Nombre del paquete final: $FINAL_RUN_FILE"

# --- 5. Crear el script de cabecera (installer.sh) ---
echo "📝 Creando el script de cabecera ($INSTALLER_TEMPLATE)..."
cat > "$INSTALLER_TEMPLATE" << 'EOF'
#!/bin/bash
# Script Autoextraíble para You2Pub

# Directorio temporal para la extracción. Usamos $TMPDIR si está disponible.
TEMP_BASE="${TMPDIR:-/tmp}"
TEMP_DIR=$(mktemp -d "$TEMP_BASE/you2pub_install_XXXXXX")
ARCHIVE_FILE="you2pub_payload.tar.gz"

# Función para limpiar y salir
cleanup() {
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    exit $1
}

# La marca que indica dónde comienza el tarball
# Usamos 'NR' para obtener el número de línea
SKIP=$(awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' "$0")

# Extraer el tarball
echo "⏳ Extrayendo archivos a: $TEMP_DIR"
# Usamos tail -n +$SKIP para saltar las primeras $SKIP líneas (el propio script)
tail -n +$SKIP "$0" > "$TEMP_DIR/$ARCHIVE_FILE"
tar -xzf "$TEMP_DIR/$ARCHIVE_FILE" -C "$TEMP_DIR"

# Entrar al directorio temporal para lanzar el instalador
pushd "$TEMP_DIR" > /dev/null

# Lanzar el script de instalación principal
echo "🚀 Ejecutando script de instalación: setup_you2pub.sh"
chmod +x setup_you2pub.sh
./setup_you2pub.sh
EXIT_STATUS=$?

# Volver al directorio anterior
popd > /dev/null

# Limpiar y terminar
cleanup $EXIT_STATUS

# Marca para el tarball: ¡NO BORRAR NI MODIFICAR ESTA LÍNEA!
__PAYLOAD_BELOW__
EOF

# --- 6. Concatenar y dar permisos ---
echo "🔗 Concatenando el script y el tarball para crear $FINAL_RUN_FILE..."
cat "$INSTALLER_TEMPLATE" "$ARCHIVE_NAME" > "$FINAL_RUN_FILE"
chmod +x "$FINAL_RUN_FILE"

# --- 7. Limpieza de archivos intermedios ---
echo "🧹 Limpiando archivos intermedios..."
rm "$ARCHIVE_NAME" "$INSTALLER_TEMPLATE"

echo "✨ ¡Paquete autoextraíble creado con éxito!"
echo "Ubicación: $FINAL_RUN_FILE"

