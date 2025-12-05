// generate_css.js

import { join } from "https://deno.land/std@0.224.0/path/mod.ts"; 

const [rootDir] = Deno.args; 
const OUTPUT_FILENAME = "style.css";
const OUTPUT_PATH = join(rootDir, 'css', OUTPUT_FILENAME); 

if (!rootDir) {
    console.error("Falta la ruta al directorio raíz.");
    Deno.exit(1);
}

const cssContent = `
/* ==================================
 * 1. Variables Globales y Base
 * ================================== */

:root {
    /* Control de Tamaño de Fuente (Modificado por js/font-size.js) */
    --font-scale-base: 16px; 

    /* Variables de Tema Light (Defectos) */
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
    --link-color: #8ab4f8; /* Azul más claro para dark mode */
    --border-color: #444444;
    --shadow-color: rgba(0, 0, 0, 0.5);
}

/* ==================================
 * 3. Estilos de Reseteo y Tipografía
 * ================================== */

body {
    background-color: var(--bg-primary);
    color: var(--text-color);
    font-size: var(--font-scale-base); /* Fuente base reactiva */
    margin: 0;
    padding: 0;
    transition: background-color 0.3s, color 0.3s;
    min-height: 100vh;
}

a {
    color: var(--link-color);
    text-decoration: none;
}

/* Los encabezados y párrafos deben usar unidades relativas (em/rem)
   para escalar con --font-scale-base */
h1, h2, h3, p {
    color: var(--text-color);
}

/* ==================================
 * Tipografía y Contenido (H1, P, PRE)
 * ================================== */

/* Título Principal del Video (H1) */
.main-content-wrapper h1 {
    font-size: 1.5em; /* Reducido de un tamaño muy grande (ej. 2em o más) */
    margin: 10px 0 10px 0;
    line-height: 1.2;
    color: var(--text-primary);
    text-align: center;
}

/* Subtítulos (H2 y H3) */
.main-content-wrapper h2 {
    font-size: 1.3em;
    margin: 20px 0 10px 0;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 5px;
    padding-left: 20px;
}

.main-content-wrapper h3 {
    font-size: 1.1em;
    margin: 15px 0 5px 0;
    color: var(--text-secondary);
}

/* Párrafos y Metadata del Canal */
.main-content-wrapper p {
    font-size: 0.95em; /* Un poco más pequeño y compacto */
    margin: 5px 0;
    line-height: 1.5;
    color: var(--text-secondary);
}

/* Etiqueta <pre> para la descripción del video y subtítulos */
.main-content-wrapper pre {
    font-family: var(--font-mono); /* Fuente monoespaciada para código/texto plano */
    font-size: 0.85em; /* Muy compacto para grandes bloques de texto */
    white-space: pre-wrap; /* Mantiene saltos de línea y respeta el ancho del contenedor */
    word-wrap: break-word; 
    background-color: var(--bg-secondary);
    padding: 15px;
    border-radius: 6px;
    border: 1px solid var(--border-color);
    line-height: 1.4;
    max-height: 300px; /* Limita la altura de la descripción para evitar que ocupe toda la pantalla */
    overflow-y: auto; /* Permite desplazamiento si excede la altura */
}

/* Ajuste específico para el contenedor de video */
#mainVideo {
    width: 100%;
    max-width: 900px; /* Limita el ancho máximo del video para que no sea excesivo en pantallas grandes */
    height: auto;
    display: block;
    margin: 20px auto; /* Centra el reproductor */
}

/* Estilos para el bloque de metadatos (Canal, Fecha) */
.channel-header p {
    font-size: 0.9em; /* Hacemos la metadata muy compacta */
    margin: 2px 0;
    text-align: left;
}


/* ==================================
 * Topbar y Controles (Posicionamiento y Agrupación)
 * ================================== */

/* Contenedor fijo en la esquina superior derecha */
#topbar {
    position: fixed;
    top: 10px;
    right: 10px;
    z-index: 1002; /* Asegura que esté sobre otros elementos */
    display: flex;
    gap: 10px; /* Espacio entre los botones */
    align-items: center;
}

/* ==================================
 * Controles de Reproducción
 * ================================== */

.controls-bar {
    display: flex; /* Habilita el modo Flexbox */
    justify-content: center; /* 🛑 Centra los elementos hijos (botones) horizontalmente */
    gap: 20px; /* Añade un espacio entre los botones */
    margin: 15px 0; /* Espacio vertical por encima y por debajo */
}

/* Estilos base para los botones (font y theme) */
.theme-toggle, .font-control, .buttons {
    padding: 8px 12px;
    cursor: pointer;
    background-color: var(--bg-secondary);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    border-radius: 4px;
    transition: background-color 0.3s, color 0.3s;
    font-size: 1em;
}

/* Estilo para el campo de búsqueda */
#searchInput {
    padding: 8px 12px;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    background-color: var(--bg-secondary);
    color: var(--text-color);
    width: 200px; /* Ajusta el ancho según sea necesario */
    transition: width 0.3s, border-color 0.3s;
}

#searchInput:focus {
    border-color: var(--link-color);
    outline: none;
}

/* ==================================
 * 4. Layout General (Sidebar y Main Content)
 * ================================== */

.main-content-wrapper {
    margin-left: 275px; /* Espacio para el sidebar abierto */
    /* 💡 Aumentamos el margen superior para que no choque con la Top Bar */
    padding-top: 60px; 
    padding-left: 50px
    transition: margin-left 0.3s, padding-top 0.3s;
    min-height: 100vh;

}

#sidebar {
    width: 250px;
    height: 100%;
    position: fixed;
    top: 0;
    left: 40px;
    background-color: var(--bg-secondary);
    border-right: 1px solid var(--border-color);
    /* 🛑 CORRECCIÓN: Quitamos el padding superior conflictivo */
    padding-top: 60px; 
    z-index: 1000;
    transition: transform 0.3s, background-color 0.3s;
    overflow-y: auto;
}

#sidebar.collapsed {
    transform: translateX(-250px);
}

#sidebar.collapsed ~ .main-content-wrapper {
    margin-left: 50px; /* Ocupa el ancho completo cuando el sidebar está colapsado */
}

/* Botón de Toggle fuera del flujo normal */
#toggleSidebar {
    position: fixed;
    top: 0;
    left: 195px;
    z-index: 1001;
    cursor: pointer;
    background-color: var(--bg-secondary);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    padding: 5px 10px;
    border-radius: 5px;
    font-size: 2em;
}

/* Estilos de la lista de canales (Sidebar) */
#sidebar-content {
    list-style: none;
    padding: 0;
    margin: 0;
}

/* ==================================
 * 4. Layout General (Sidebar y Main Content)
 * ================================== */

/* ... Código existente ... */

/* Estilos de la lista de canales (Sidebar) */
#sidebar-content {
    list-style: none;
    padding: 0;
    margin: 0;
}

/* 💡 CORRECCIÓN AÑADIDA: Asegurar que el texto dentro del menú escale */
#sidebar-content a, 
#sidebar-content .menu-name {
    /* Usamos una unidad relativa a la variable base, ajustada ligeramente si es necesario */
    font-size: 0.9em; /* Hereda de body, pero lo hacemos un poco más pequeño para ser compacto */
    line-height: 1.2; 
}
/* Si eso no funciona, forzamos la herencia de la variable base */
/* #sidebar-content * { font-size: var(--font-scale-base); } */ 


.sidebar-item a {
    display: flex;
    align-items: center;
    padding: 10px 15px;
    color: var(--text-color);
    text-decoration: none;
}

.sidebar-item a:hover {
    background-color: var(--border-color);
}

.menu-icon {
    width: 60px;
    height: 60px;
    margin-right:5px;
    border-radius: 50%;
    object-fit: cover;"
}


/* ==================================
 * 5. Video Grid (lazy-load.js)
 * ================================== */

.video-list-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 20px;
}

.video-item {
    background-color: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    box-shadow: 0 2px 4px var(--shadow-color);
    overflow: hidden;
    transition: transform 0.2s;
}

.video-item:hover {
    transform: translateY(-5px);
    box-shadow: 0 4px 8px var(--shadow-color);
}

.video-item img {
    width: 100%;
    height: auto;
    display: block;
    aspect-ratio: 16 / 9; /* Asegura un ratio de imagen consistente */
    object-fit: cover;
}

.video-item-content {
    padding: 10px 15px;
}

/* ==================================
 * Canal y Banner Fijo
 * ================================== */

/* Contenedor del Banner: Altura fija, ocultar desbordamiento */
.banner-container-channel {
    width: 100%;
    height: 60px;
    overflow: hidden;
    position: relative; /* Para posicionar el botón Home */
    background-color: var(--bg-primary); /* Fallback */
}

/* La imagen del banner */
.main-banner {
    width: 100%;
    /* Asegura que la imagen cubra el contenedor y se centre verticalmente */
    height: 100%;
    object-fit: cover; 
    object-position: center;
    display: block;
}

/* Botón Home sobre el banner */
.home-button-banner {
    top: 10px;
    right: 10px;
    z-index: 1003; 
    background-color: var(--bg-secondary);
    color: var(--text-color);
    border-radius: 50%;
    padding: 8px;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 4px var(--shadow-color);
}
.home-button-banner svg {
    width: 100%;
    height: 100%;
    fill: currentColor;
}

/* Contenido del Canal (encabezado, icono, descripción) */
.channel-header {
    padding: 20px 20px 0 20px;
    display: flex;
    flex-direction: column;
    align-items: normal;
    text-align: left;
}

.channel-icon-large {
    width: 100px;
    height: 100px;
    border-radius: 50%;
    object-fit: cover;
    margin-bottom: 10px;
    border: 3px solid var(--border-color);
    position: absolute;
    top: 60px;
}

.channel-description {
    max-width: 800px;
    margin: 10px auto 20px auto;
    font-size: 0.9em;
    opacity: 0.8;
}



`;

// Lógica para escribir el archivo (asumiendo que está dentro de una función asíncrona)
async function generateCss(rootDir) {
    try {
        await Deno.mkdir(join(rootDir, 'css'), { recursive: true });
        await Deno.writeTextFile(OUTPUT_PATH, cssContent);
        console.log(`  ✅ Generado archivo CSS: ${OUTPUT_PATH}`);
    } catch (e) {
        console.error(`ERROR al generar style.css: ${e}`);
        Deno.exit(1);
    }
}

generateCss(rootDir);
