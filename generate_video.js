// generate_video.js
// Uso: deno run --allow-read --allow-write generate_video.js <video_path>

import { join, basename } from "https://deno.land/std@0.211.0/path/mod.ts";
import { readVideoMetadata, generateHtmlWrapper } from './utils.js';

const [videoPath] = Deno.args;
const OUTPUT_FILENAME = "index.html";

// 💡 CONTROL DE SUBTÍTULOS POR DEFECTO
// Cambia a 'true' para que el primer subtítulo se active automáticamente.
// Cambia a 'false' para que el usuario deba activar los subtítulos manualmente.
const DEFAULT_SUBTITLE_ACTIVE = true; // <--- ¡Toca aquí!

if (!videoPath) {
    console.error("Falta la ruta al directorio del video.");
    Deno.exit(1);
}

// Función auxiliar para leer y concatenar subtítulos para el índice
async function readSubtitlesContent(videoPath) {
    let allSubtitles = "";
    try {
        for await (const entry of Deno.readDir(videoPath)) {
            // Buscamos archivos .vtt o .srt
            if (entry.name.endsWith('.vtt') || entry.name.endsWith('.srt')) {
                const filePath = join(videoPath, entry.name);
                const content = await Deno.readTextFile(filePath);
                
                // Limpiamos contenido: elimina marcas de tiempo y encabezados VTT/SRT
                let cleanContent = content
                    .replace(/WEBVTT\n/, '')
                    .replace(/(\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}(?:[^\n]*\n)?)/g, '') // Marcas de tiempo VTT
                    .replace(/(\d+\n\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}\n)/g, '') // Marcas de tiempo SRT
                    .replace(/\n\d+\n/g, '\n') // Números de subtítulo (SRT)
                    .replace(/\[.*\]/g, '') // Posibles indicaciones entre corchetes
                    .trim();

                allSubtitles += `\n--- Subtítulos (${entry.name}) ---\n${cleanContent}\n`;
            }
        }
    } catch (e) {
        console.warn(`Advertencia al leer subtítulos en ${videoPath}: ${e.message}`);
    }
    return allSubtitles;
}

async function generateVideoPage(videoPath) {
    const videoDirName = basename(videoPath);
    
    // 🛑 AGREGADO: Obtener el nombre de la carpeta del canal (un nivel arriba)
    const channelDirName = basename(join(videoPath, '..')); 
    
    // 🛑 COMPROBACIÓN CRÍTICA DE METADATOS 🛑
    const metadata = await readVideoMetadata(videoPath);
    if (!metadata) {
        console.error(`  ❌ ERROR: No se pudieron leer los metadatos del video (${videoDirName}). Asegúrate de que existe un archivo *.info.json.`);
        return; // Salir si no hay metadatos
    }

    const videoID = metadata.id; 
    const videoFilename = `${videoID}.mp4`;
    const localJpgFilename = `${videoID}.jpg`;
    const thumbnailUrl = `./${localJpgFilename}`; 
    const youtubeUrl = `https://www.youtube.com/watch?v=${metadata.id}`;
    
    // Contenido completo de subtítulos para crawlers y el bloque <details>
    const fullSubtitlesContent = await readSubtitlesContent(videoPath);
    const hasSubtitles = fullSubtitlesContent.trim() !== "";

    // Metadatos y fecha
    const uploadDate = metadata.upload_date ? new Date(
        parseInt(metadata.upload_date.substring(0, 4)),
        parseInt(metadata.upload_date.substring(4, 6)) - 1,
        parseInt(metadata.upload_date.substring(6, 8))
    ).toLocaleDateString('es-ES') : 'N/A';

    // Construye las pistas de subtítulos <track> para el player HTML5
    const subtitleTracks = [];
    let isFirstTrack = true; // Para aplicar 'default' solo al primer track si está activo
    
    // Uso un fallback para Intl si no está disponible (ej. en algunos entornos Deno sin flags)
    const displayNames = typeof Intl !== 'undefined' && Intl.DisplayNames ? new Intl.DisplayNames(['es'], { type: 'language' }) : { of: (code) => code };

    for await (const entry of Deno.readDir(videoPath)) {
        if (entry.name.endsWith('.vtt') || entry.name.endsWith('.srt')) {
            const parts = entry.name.split('.');
            // Intenta obtener el código de idioma justo antes de la extensión
            const langCode = parts.length > 1 ? parts[parts.length - (entry.name.endsWith('.srt') ? 2 : 2)] : 'desconocido'; 

            const langName = displayNames.of(langCode) || langCode;
            const label = entry.name.includes('.auto.') ? `${langName} (Auto)` : langName;
            
            // Lógica de activación por defecto basada en la variable
            let defaultAttribute = '';
            if (DEFAULT_SUBTITLE_ACTIVE && isFirstTrack) {
                defaultAttribute = ' default';
                isFirstTrack = false; // Solo el primero obtiene 'default'
            }

            subtitleTracks.push(`<track kind="subtitles" src="./${entry.name}" srclang="${langCode}" label="${label}"${defaultAttribute}>`);
        }
    }

    // ⭐️ RUTAS CLAVE PARA EL VIDEO (3 niveles de profundidad) ⭐️
    // El CSS sigue siendo '../../css/style.css'
    const CSS_PATH_RELATIVE = '../../css/style.css'; 

    // --- Contenido HTML ---
    const videoPlayer = `
        <div id="topbar" class="topbar-controls">

            <button id="fontDecrease" class="font-control" title="Disminuir Tamaño de Fuente">A-</button> 
            <button id="fontIncrease" class="font-control" title="Aumentar Tamaño de Fuente">A+</button>
            <button id="themeToggle" class="theme-toggle" title="Alternar Modo Claro/Oscuro">
                Cambiar Tema
            </button>
            <a href="../../index.html" class="home-button-banner" title="Volver a la Página Principal">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
                </svg>
            </a>
    
        </div>

        <nav id="sidebar" class="collapsed">
            <button id="toggleSidebar" title="Alternar menú">☰</button>
            <div class="sidebar-header">Canales</div>
            <ul id="sidebar-content">
                <li class="sidebar-item" style="padding: 10px; color: var(--text-secondary);">Cargando canales...</li>
            </ul>
        </nav>

        <div class="main-content-wrapper">

            <header class="channel-header">

                <div class="banner-container-channel">
                    <img src="../img/banner_${channelDirName}.jpg" alt="Banner del Canal ${metadata.uploader}" class="main-banner"/>
                </div>

                <h1>${metadata.fulltitle || metadata.title}</h1>
                <p><strong>Canal:</strong> <a href="../index.html">${metadata.uploader}</a></p>
                <p><strong>Fecha de subida:</strong> ${uploadDate}</p>
            </header>

            <hr>

            <video controls poster="${thumbnailUrl}" id="mainVideo">
                <source src="./${videoFilename}" type="video/mp4">
                ${subtitleTracks.join('\n')} Tu navegador no soporta el elemento de video.
            </video>
        
            <div class="controls-bar">
                <button class="buttons" id="back30s">⏪ Atrás 30s</button>
                <button class="buttons" id="forward30s"> Adelante 30s ⏩</button>
            </div>

            <hr>

            <div class="description">
                <h3>📝 Descripción del Video</h3>
                <pre>${metadata.description || 'Sin descripción.'}</pre>
            </div>

            <div class="info-bar">
                <div>
                    <h3>🔗 Enlaces</h3>
                    <a href="${youtubeUrl}" target="_blank" rel="noopener noreferrer">URL Original en YouTube</a>
                </div>
                <div>
                    <h3>⬇️ Descarga</h3>
                    <a href="./${videoFilename}" download="${metadata.title}.mp4" style="font-size: 1.1em; padding: 5px 10px; border: 1px solid #ccc; border-radius: 4px; text-decoration: none;">
                        Descargar Video 📥
                    </a>
                </div>
            </div>

            <hr>

            ${hasSubtitles ? `
            <details style="margin-top: 20px;">
                <summary>
                    <h3>📜 Subtítulos Completos (para motores de búsqueda - haz click para ver)</h3>
                </summary>
                <div style="max-height: 400px; overflow-y: auto; padding: 10px; border: 1px solid #eee;">
                    <pre>${fullSubtitlesContent}</pre>
                </div>
            </details>
            ` : ''}

        </div> 
        
        <div style="position: absolute; left: -9999px;">
            <a href="../../menu.html">Ver lista completa de canales para indexación</a>
        </div>

        <script src="../../js/theme-toggle.js" defer></script>
        <script src="../../js/font-size.js" defer></script> 
        <script src="../../js/menu.js" type="module" defer></script>
        <script src="../../js/video-page.js" defer></script>
    `;

    // 5. Generar la página HTML completa
    const CSS_PATH = CSS_PATH_RELATIVE;

    const htmlContent = generateHtmlWrapper(metadata.title, videoPlayer, CSS_PATH);
    await Deno.writeTextFile(join(videoPath, OUTPUT_FILENAME), htmlContent);
    console.log(`  ✅ Generada página de video: ${videoDirName}`);
}

generateVideoPage(videoPath);
