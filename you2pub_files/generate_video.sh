#!/bin/bash

# Uso: ./generate_video.sh <video_path>
VIDEO_PATH=$1
OUTPUT_FILENAME="index.html"

if [[ -z "$VIDEO_PATH" ]]; then
    echo "❌ ERROR: Falta la ruta al video."
    exit 1
fi

cd "$VIDEO_PATH" || exit 1

VIDEO_ID=$(basename "$(pwd)")

# Buscamos el archivo de metadatos
METADATA_FILE=$(ls *.info.json 2>/dev/null | head -n 1)
[[ -z "$METADATA_FILE" ]] && METADATA_FILE="metadata.json"

if [[ ! -f "$METADATA_FILE" ]]; then
    echo "   ❌ ERROR: No se encontró archivo de metadatos en $(pwd)"
    exit 1
fi

# --- 1. LIMPIEZA DE METADATOS ---
sed -i 's/\xc2\xa0/ /g' -- "$METADATA_FILE"

# --- 2. EXTRAER METADATOS ---
TITLE=$(jq -r '.title // "Video sin título"' "$METADATA_FILE" | sed 's/"/\\"/g')
CHANNEL=$(jq -r '.channel // .uploader // "Canal Desconocido"' "$METADATA_FILE")
DESCRIPTION=$(jq -r '.description // "Sin descripción."' "$METADATA_FILE" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
UPLOAD_DATE=$(jq -r '.upload_date // "Desconocida"' "$METADATA_FILE")

# Buscar archivo de video
FINAL_VIDEO_FILENAME=$(ls *.mp4 2>/dev/null | head -n 1)

# --- 3. PROCESAR SUBTÍTULOS (VTT) ---
TRANSCRIPT_HTML=""
TRACKS_HTML=""
ALL_VTT_TEXT=""
VTT_FILES=$(ls *.vtt 2>/dev/null)

if [[ -n "$VTT_FILES" ]]; then
    for vtt in $VTT_FILES; do
        LANG_CODE=$(echo "$vtt" | rev | cut -d'.' -f2 | rev)
        TRACKS_HTML+="\n                    <track kind=\"subtitles\" src=\"./$vtt\" srclang=\"$LANG_CODE\" label=\"$LANG_CODE\">"
        CLEAN_TEXT=$(sed '/WEBVTT/d; /[0-9][0-9]:[0-9][0-9]/d; s/<[^>]*>//g; /^$/d' "$vtt")
        ALL_VTT_TEXT+="\n--- Idioma: $LANG_CODE ---\n$CLEAN_TEXT\n"
    done
    
    if [[ -n "$ALL_VTT_TEXT" ]]; then
        TRANSCRIPT_HTML="
        <details class=\"subtitles-accordion\" style=\"margin-top: 20px; border: 1px solid var(--border-color); border-radius: 8px; padding: 10px;\">
            <summary style=\"cursor: pointer; font-weight: bold; color: var(--text-primary);\">Ver Transcripción (SEO)</summary>
            <pre style=\"white-space: pre-wrap; font-family: inherit; font-size: 0.9em; color: var(--text-secondary); margin-top: 10px; max-height: 300px; overflow-y: auto;\">
$ALL_VTT_TEXT
            </pre>
        </details>"
    fi
fi

# --- 4. GENERACIÓN DEL HTML ---
cat <<EOF > "$OUTPUT_FILENAME"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$TITLE</title>
    <link rel="stylesheet" href="../../css/style.css">
</head>
<body>
    <div id="topbar" class="topbar-controls">
        <button id="themeToggle" class="theme-toggle">Cambiar Tema</button>
        <a href="../index.html" class="home-button-banner">Volver al Canal</a>
    </div>

    <nav id="sidebar" class="collapsed">
        <button id="toggleSidebar" title="Alternar menú">☰</button>
        <div class="sidebar-header">Canales</div>
        <ul id="sidebar-content">
            <li class="sidebar-item" style="padding: 10px; color: var(--text-secondary);">Cargando canales...</li>
        </ul>
    </nav>

    <div class="main-content-wrapper">
        <div class="banner-container-video" style="width: 100%; max-height: 150px; overflow: hidden; background: #222;">
            <img src="../img/banner.png" alt="Banner Canal" style="width: 100%; object-fit: cover;" onerror="this.style.display='none';">
        </div>

        <div class="video-container" style="padding: 20px; max-width: 1000px; margin: auto;">
            <div class="video-wrapper" style="background: #000; border-radius: 8px; overflow: hidden; aspect-ratio: 16/9;">
                <video id="mainPlayer" controls poster="./${VIDEO_ID}.jpg" style="width: 100%; height: 100%;">$TRACKS_HTML
                    <source src="./$FINAL_VIDEO_FILENAME" type="video/mp4">
                    Tu navegador no soporta el tag de video.
                </video>
            </div>
            
            <div class="video-info" style="margin-top: 20px;">
                <h1>$TITLE</h1>
                <p style="color: var(--text-secondary);">Canal: $CHANNEL | Subido el: $UPLOAD_DATE</p>
                <hr style="border: 0; border-top: 1px solid var(--border-color); margin: 20px 0;">
                <div class="description-box" style="white-space: pre-wrap; line-height: 1.6;">$DESCRIPTION</div>
                
                $TRANSCRIPT_HTML
            </div>
        </div>
    </div>

    <script src="../../js/theme-toggle.js" defer></script>
    <script type="module">
        import { renderMenu } from '../../js/menu_base.js';
        document.addEventListener('DOMContentLoaded', () => {
            renderMenu('../../'); // Subimos dos niveles para llegar a js/menu_data.json
        });
    </script>
</body>
</html>
EOF

echo "✨ Video '$VIDEO_ID' generado con Sidebar, Banner y Transcripción."
