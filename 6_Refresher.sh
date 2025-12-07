#!/bin/bash

# --- Constantes ---
DOWNLOAD_ROOT="$HOME/public_html/You2Pub" # Carpeta raíz de todas las descargas
BIN_DIR="$HOME/.local/bin"
TEMP_LIST="/tmp/ChannelsList.tmp" # Usamos una extensión .tmp para evitar conflictos

# 1. Crear o truncar (vaciar) el archivo temporal ChannelsList.tmp
:> "$TEMP_LIST"

echo DOWNLOAD_ROOT=$DOWNLOAD_ROOT
# 2. Cambiar al directorio de trabajo
cd "$DOWNLOAD_ROOT" || { echo "Error: El directorio '$DOWNLOAD_ROOT' no existe."; exit 1; }
pwd

# 3. Buscar y concatenar el contenido de todos los archivos 'xcron'
#    dentro de los subdirectorios inmediatos de Videos (profundidad 1)
#    y dirigir la salida al archivo temporal.

echo "find $DOWNLOAD_ROOT -maxdepth 2 -name 'xcron' -exec cat {} + >> $TEMP_LIST"


find "$DOWNLOAD_ROOT" -maxdepth 2 -name "xcron" -exec cat {} + >> "$TEMP_LIST"
exit

# 4. Regresar al directorio original
cd - > /dev/null

echo "Ficheros 'xcron' recopilados en '$TEMP_LIST'."
echo "Iniciando refresco de canales..."

exit

# 5. Leer el archivo temporal línea por línea y separando por comas.
#    IFS=, : Establece la coma como separador de campos.
#    -r : Evita que las barras invertidas sean interpretadas.
#    El 'while read' es robusto contra espacios en las URLs/nombres.
while IFS=, read -r URL RES; do
    
    # Limpieza de las variables por si hay espacios en blanco
    URL=$(echo "$URL" | xargs)
    RES=$(echo "$RES" | xargs)

    if [ -n "$URL" ]; then # Solo ejecutar si la URL no está vacía
        echo "--> Refrescando: $URL con calidad $RES"
        
        # Ejecutar el script de descarga con los argumentos
        $BIN_DIR/1_downloader.sh "$URL" "$RES"
    fi
    
done < "$TEMP_LIST"

# 6. Limpieza final
rm "$TEMP_LIST"

echo "Proceso de refresco completado."
