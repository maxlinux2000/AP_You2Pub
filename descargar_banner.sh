#!/bin/bash

# Este script descarga un archivo de una URL, usa 'file' para determinar
# su extensión real (como .jpg, .png, .webp) y lo renombra.
# Si el formato no es JPG, lo convierte a JPG usando ffmpeg.

# Verificar si se proporcionó una URL
if [ -z "$1" ]; then
    echo "ERROR: Debes proporcionar la URL del banner como primer argumento."
    echo "Uso: $0 <url_del_banner>"
    exit 1
fi

BANNER_URL="$1"
TEMP_FILENAME="banner_original" # Nombre temporal del archivo original sin extensión
FINAL_JPG_FILENAME="banner.jpg" # Nombre final del archivo convertido a JPG

echo "🚀 Descargando banner desde: $BANNER_URL"

# 1. Descargar el archivo de forma silenciosa.
# Usamos -o para forzar el nombre temporal "banner_original"
curl -s -o "$TEMP_FILENAME" "$BANNER_URL"

if [ $? -ne 0 ]; then
    echo "ERROR: Falló la descarga del banner. Verifica la URL."
    rm -f "$TEMP_FILENAME" # Limpiar el archivo temporal
    exit 1
fi

# 2. Usar el comando 'file' para determinar el tipo MIME/extensión
MIME_TYPE=$(file --mime-type -b "$TEMP_FILENAME")

echo "🔍 Tipo MIME detectado: $MIME_TYPE"

# 3. Determinar si es JPG o necesita conversión
if [ "$MIME_TYPE" == "image/jpeg" ]; then
    echo "✅ El banner ya es JPEG. Renombrando..."
    mv "$TEMP_FILENAME" "$FINAL_JPG_FILENAME"
    echo "✅ Archivo final: $FINAL_JPG_FILENAME"
else
    echo "🔄 El banner no es JPEG ($MIME_TYPE). Convirtiendo a JPG con FFmpeg..."
    # Convertir a JPG. ffmpeg es muy robusto y puede manejar la mayoría de formatos de imagen.
    # Usamos -y para sobrescribir si ya existe un banner.jpg
    ffmpeg -i "$TEMP_FILENAME" -y "$FINAL_JPG_FILENAME"

    if [ $? -ne 0 ]; then
        echo "ERROR: Falló la conversión a JPG con FFmpeg."
        rm -f "$TEMP_FILENAME" # Limpiar el archivo temporal
        exit 1
    fi

    echo "✅ Conversión a JPG completada."
    rm -f "$TEMP_FILENAME" # Eliminar el archivo original descargado
    echo "✅ Archivo final: $FINAL_JPG_FILENAME"
fi
