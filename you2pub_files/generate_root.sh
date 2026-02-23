#!/bin/bash

# ========================================================
# generate_root.sh - SSR + Sitemap Global (Índice)
# ========================================================

ROOT_DIR=$1
OUTPUT_FILENAME="index.html"
SITEMAP_GLOBAL="sitemap.txt"
TARGET_TOTAL_VIDEOS=500 

if [[ -z "$ROOT_DIR" ]]; then
    echo "❌ ERROR: Falta la ruta al directorio raíz."
    exit 1
fi

cd "$ROOT_DIR" || exit 1

# 1. Preparar conteos y archivos
CANAL_COUNT=$(find . -maxdepth 2 -name "metadatos_base.json" | wc -l)
LIMIT_PER_CHANNEL=$(echo "scale=0; ($TARGET_TOTAL_VIDEOS + $CANAL_COUNT - 1) / $CANAL_COUNT" | bc)
[[ "$LIMIT_PER_CHANNEL" -lt 2 ]] && LIMIT_PER_CHANNEL=2
#"
echo "🚀 Generando Home y Sitemap Global para $CANAL_COUNT canales..."

# Limpiar/Crear el sitemap global
> "$SITEMAP_GLOBAL"

# Parte superior del HTML
cat <<EOF > "$OUTPUT_FILENAME"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>You2Pub - Inicio</title>
    <link rel="stylesheet" href="./css/style.css">
</head>
<body>
    <div id="topbar" class="topbar-controls">
        <button id="themeToggle" class="theme-toggle">Cambiar Tema</button>
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
            <img src="./img/banner.png" alt="Banner" class="main-banner" onerror="this.style.display='none';" style="width:100%; max-height:200px; object-fit:cover;"/>
        </div>
        <header style="padding: 20px 20px 0 20px;">
            <h1 style="margin:0;"><a href="./" style="text-decoration: none; color: inherit;">You2Pub</a></h1>
            <p style="color: var(--text-secondary); margin-top: 5px;">
                Home: Mostrando selección de vídeos de <strong>$CANAL_COUNT</strong> canales locales.
            </p>
        </header>

        <div id="videoListContainer" class="video-list-grid" style="padding: 20px;">
EOF

# 2. Inyectar tarjetas y recolectar Sitemaps de canales
VIDEO_COUNTER=0
for meta_file in */metadatos_base.json; do
    CANAL_FOLDER=$(dirname "$meta_file")
    
    # Añadimos el sitemap del canal al sitemap global
    # Verificamos si existe el sitemap_videos.txt en ese canal
    if [[ -f "$CANAL_FOLDER/sitemap_videos.txt" ]]; then
        echo "./$CANAL_FOLDER/sitemap_videos.txt" >> "$SITEMAP_GLOBAL"
    fi

    # Aplicamos limpieza de Non-Breaking Spaces
    sed -i 's/\xc2\xa0/ /g' -- "$meta_file"

    # Inyección de video-cards para la Home
    while read -r vid_id vid_title; do
        ((VIDEO_COUNTER++))
        
        VIDEO_URL="./${CANAL_FOLDER}/${vid_id}/index.html"
        THUMB_URL="./${CANAL_FOLDER}/${vid_id}/${vid_id}.thumb.jpg"

        cat <<CARD >> "$OUTPUT_FILENAME"
            <div class="video-item">
                <a href="$VIDEO_URL">
                    <img src="$THUMB_URL" alt="$vid_title" loading="lazy" onerror="this.src='./js/placeholder.png'">
                </a>
                <div class="video-item-content">
                    <h3><a href="$VIDEO_URL">$vid_title</a></h3>
                    <p class="channel-name-text">Canal: $CANAL_FOLDER</p>
                </div>
            </div>
CARD
    done < <(jq -r '.[:'"$LIMIT_PER_CHANNEL"'][] | "\(.id)\t\(.title)"' "$meta_file" 2>/dev/null)
done

# 3. Cerrar el HTML
cat <<EOF >> "$OUTPUT_FILENAME"
        </div>
    </div>
    
    <script src="./js/theme-toggle.js" defer></script>
    <script type="module">
        import { renderMenu } from './js/menu_base.js';
        document.addEventListener('DOMContentLoaded', () => {
            renderMenu('./');
        });
    </script>
</body>
</html>
EOF

echo "✨ Proceso finalizado:"
echo "   - index.html: $VIDEO_COUNTER videos inyectados."
echo "   - $SITEMAP_GLOBAL: Creado con las rutas a todos los canales."

