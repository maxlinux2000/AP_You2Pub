#!/bin/bash

ROOT_DIR=$1
OUTPUT_JSON="$ROOT_DIR/js/menu_data.json"

if [[ -z "$ROOT_DIR" ]]; then
    echo "❌ ERROR: Falta la ruta raíz."
    exit 1
fi

mkdir -p "$ROOT_DIR/js"

echo "[" > "$OUTPUT_JSON"

FIRST=true
# Buscamos directorios reales (canales)
find "$ROOT_DIR" -maxdepth 1 -mindepth 1 -type d | sort | while read -r folder; do
    name=$(basename "$folder")
    [[ "$name" =~ ^(js|css|img|stuff)$ ]] && continue
    
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo "," >> "$OUTPUT_JSON"
    fi

    # Guardamos solo el nombre de la carpeta
    echo "  { \"folder\": \"$name\" }" >> "$OUTPUT_JSON"
done

echo "]" >> "$OUTPUT_JSON"
echo "✅ menu_data.json generado."
