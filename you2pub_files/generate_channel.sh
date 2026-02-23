#!/bin/bash

# ========================================================
# generate_channel.sh - SSR + Sitemap de Vídeos
# ========================================================

CHANNEL_PATH=$1
OUTPUT_FILENAME="index.html"
SITEMAP_FILENAME="sitemap_videos.txt"
METADATA_BASE_FILE="metadatos_base.json"

if [[ -z "$CHANNEL_PATH" ]]; then
    echo "❌ ERROR: Falta la ruta al directorio del canal."
    exit 1
fi

cd "$CHANNEL_PATH" || exit 1

CHANNEL_NAME=$(basename "$(pwd)")
CHANNEL_INFO_JSON="channel.info.json"

echo "📂 Procesando canal: $CHANNEL_NAME"

# --- 1. LIMPIEZA Y SANEADO ---
if [[ -f "$METADATA_BASE_FILE" ]]; then
    sed -i 's/\xc2\xa0/ /g' -- "$METADATA_BASE_FILE"
fi

# Limpiamos el sitemap antiguo si existe
> "$SITEMAP_FILENAME"

CHANNEL_TITLE="$CHANNEL_NAME"
CHANNEL_DESCRIPTION="Sin descripción."
ICON_PATH="./img/icon.png"
BANNER_PATH="./img/banner.png"

if [[ -f "$CHANNEL_INFO_JSON" ]]; then
    sed -i 's/\xc2\xa0/ /g' -- "$CHANNEL_INFO_JSON"
    CHANNEL_TITLE=$(jq -r '.title // .channel // empty' "$CHANNEL_INFO_JSON")
    CHANNEL_DESCRIPTION=$(jq -r '.description // empty' "$CHANNEL_INFO_JSON" | head -c 200)
    [[ -z "$CHANNEL_TITLE" ]] && CHANNEL_TITLE="$CHANNEL_NAME"
    [[ -z "$CHANNEL_DESCRIPTION" ]] && CHANNEL_DESCRIPTION="Canal de contenido local."
fi

# --- 2. INICIO DEL HTML ---
cat <<EOF > "$OUTPUT_FILENAME"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canal: $CHANNEL_TITLE</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div id="topbar" class="topbar-controls">
        <button id="themeToggle" class="theme-toggle">Cambiar Tema</button>
        <a href="../index.html" class="home-button-banner">Inicio</a>
    </div>

    <nav id="sidebar" class="collapsed">
        <button id="toggleSidebar" title="Alternar menú">☰</button>
        <div class="sidebar-header">Canales</div>
        <ul id="sidebar-content">
            <li class="sidebar-item" style="padding: 10px; color: var(--text-secondary);">Cargando canales...</li>
        </ul>
    </nav>

    <div class="main-content-wrapper">
        <div class="banner-container-channel">
            <img src="$BANNER_PATH" alt="Banner" class="main-banner" onerror="this.style.display='none';" style="width:100%; max-height:200px; object-fit:cover;"/>
        </div>
        <div class="channel-header" style="padding: 20px;">
            <img src="$ICON_PATH" alt="Icono" class="channel-icon-large" style="width:80px; border-radius:50%;" onerror="this.src='../js/default-icon.png';">
            <h1>$CHANNEL_TITLE</h1>
            <p class="channel-description">$CHANNEL_DESCRIPTION</p>
        </div>
        
        <div id="videoListContainer" class="video-list-grid" style="padding: 20px;">
EOF

# --- 3. INYECCIÓN DE VIDEOS Y SITEMAP ---
VIDEO_COUNTER=0
if [[ -f "$METADATA_BASE_FILE" ]]; then
    
    # Procesamos el JSON para el HTML y el Sitemap simultáneamente
    while read -r vid_id vid_title; do
        ((VIDEO_COUNTER++))
        
        # Rutas
        VIDEO_URL="./${vid_id}/index.html"
        THUMB_URL="./${vid_id}/${vid_id}.thumb.jpg"

        # 1. Añadir al sitemap (ruta relativa simple)
        echo "$VIDEO_URL" >> "$SITEMAP_FILENAME"

        # 2. Inyectar Card en el HTML
        cat <<CARD >> "$OUTPUT_FILENAME"
            <div class="video-item">
                <a href="$VIDEO_URL">
                    <img src="$THUMB_URL" alt="$vid_title" loading="lazy" onerror="this.src='../js/placeholder.png'">
                </a>
                <div class="video-item-content">
                    <h3><a href="$VIDEO_URL">$vid_title</a></h3>
                    <p class="video-meta">ID: $vid_id</p>
                </div>
            </div>
CARD
    done < <(jq -r '.[] | "\(.id)\t\(.title)"' "$METADATA_BASE_FILE" 2>/dev/null)
fi

# --- 4. CIERRE DEL HTML ---
cat <<EOF >> "$OUTPUT_FILENAME"
        </div>
    </div>
    
    <script src="../js/theme-toggle.js" defer></script>
    <script type="module">
        import { renderMenu } from '../js/menu_base.js';
        document.addEventListener('DOMContentLoaded', () => {
            renderMenu('../');
        });
    </script>
</body>
</html>
EOF

echo "✨ Canal '$CHANNEL_NAME' finalizado."
echo "   - index.html: $VIDEO_COUNTER videos."
echo "   - $SITEMAP_FILENAME: Generado con éxito."

