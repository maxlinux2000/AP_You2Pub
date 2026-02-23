#!/bin/bash

# ========================================================
# generate_css.sh - Generador del Estilo Visual (CSS)
# ========================================================
# Uso: ./generate_css.sh <root_dir>

ROOT_DIR=$1
CSS_DIR="css"
OUTPUT_FILENAME="style.css"

if [[ -z "$ROOT_DIR" ]]; then
    echo "❌ ERROR: Falta la ruta al directorio raíz (ej: .)"
    exit 1
fi

# Asegurarse de que el directorio css existe
mkdir -p "$ROOT_DIR/$CSS_DIR"

echo "🎨 Generando archivo de estilos en $ROOT_DIR/$CSS_DIR/$OUTPUT_FILENAME..."

# Usamos un 'cat' con un heredoc para volcar todo el contenido del CSS
cat <<EOF > "$ROOT_DIR/$CSS_DIR/$OUTPUT_FILENAME"
/* ==================================
 * 1. Variables Globales y Base
 * ================================== */

:root {
    /* Control de Tamaño de Fuente (Modificado por js/font-size.js) */
    --font-scale-base: 16px; 

    /* Variables de Tema Light (Defecto) */
    --bg-primary: #f8f8f8;
    --bg-secondary: #ffffff;
    --text-color: #1a1a1a;
    --link-color: #0066cc;
    --border-color: #cccccc;
    --shadow-color: rgba(0, 0, 0, 0.1);
}

/* ==================================
 * 2. Tema Oscuro (.dark-mode)
 * ================================== */

body.dark-mode {
    --bg-primary: #1e1e1e;
    --bg-secondary: #252526;
    --text-color: #f0f0f0;
    --link-color: #8ab4f8;
    --border-color: #3e3e3e;
    --shadow-color: rgba(0, 0, 0, 0.3);
}

/* ==================================
 * 3. Estilos Base
 * ================================== */

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background-color: var(--bg-primary);
    color: var(--text-color);
    font-size: var(--font-scale-base);
    line-height: 1.5;
    transition: background-color 0.3s, color 0.3s;
}

a {
    color: var(--link-color);
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

/* ==================================
 * 4. Layout: Sidebar & Main Content
 * ================================== */

.main-content-wrapper {
    margin-left: 0;
    transition: margin-left 0.3s ease;
    min-height: 100vh;
}

/* Ajuste cuando la sidebar NO está colapsada */
#sidebar:not(.collapsed) + .main-content-wrapper {
    margin-left: 250px;
}

/* ==================================
 * 5. Grid de Videos
 * ================================== */

.video-list-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 20px;
    padding: 20px;
}

.video-item {
    background-color: var(--bg-secondary);
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 2px 5px var(--shadow-color);
    transition: transform 0.2s ease;
}

.video-item:hover {
    transform: translateY(-5px);
}

.video-thumbnail {
    width: 100%;
    aspect-ratio: 16 / 9;
    object-fit: cover;
    display: block;
}

.video-info {
    padding: 12px;
}

.video-title {
    font-size: 1rem;
    font-weight: bold;
    margin: 0 0 8px 0;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

/* ==================================
 * 6. Componentes (Topbar, Banner, etc.)
 * ================================== */

.topbar-controls {
    position: sticky;
    top: 0;
    z-index: 1000;
    background-color: var(--bg-secondary);
    padding: 10px 20px;
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    border-bottom: 1px solid var(--border-color);
}

.banner-container-channel {
    width: 100%;
    height: 200px;
    overflow: hidden;
    background-color: #333;
}

.main-banner {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.channel-header {
    padding: 20px;
    position: relative;
}

.channel-icon-large {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    border: 3px solid var(--bg-secondary);
    margin-top: -60px;
    background-color: var(--bg-secondary);
}

/* Estilos de botones básicos */
button {
    cursor: pointer;
    padding: 8px 12px;
    border-radius: 4px;
    border: 1px solid var(--border-color);
    background-color: var(--bg-secondary);
    color: var(--text-color);
}

button:hover {
    filter: brightness(0.9);
}

EOF

echo "✅ style.css generado correctamente."

