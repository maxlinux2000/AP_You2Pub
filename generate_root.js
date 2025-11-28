// generate_root.js (VERSIÓN FINALIZADA PARA EL HOME)
// Uso: deno run --allow-read --allow-write generate_root.js <root_dir>

import { join } from "https://deno.land/std@0.211.0/path/mod.ts";
import { readVideoMetadata, generateHtmlWrapper } from './utils.js'; // Asumimos utils.js está en el root

const [rootDir] = Deno.args;
const OUTPUT_FILENAME = "index.html";

// rootDir es la carpeta que contiene los canales (ej: 'Videos')
const VIDEOS_DIR = rootDir; 

if (!rootDir) {
    console.error("Falta la ruta al directorio raíz.");
    Deno.exit(1);
}

// 💡 Parámetros
const VIDEOS_PER_PAGE = 50; 

// ===========================================
// FUNCIÓN DE FILTRADO (Mantener sin cambios)
// ===========================================
async function checkFiles(videoPath, videoId) {
    const videoFilename = `${videoId}.mp4`;
    const thumbnailFilename = `${videoId}.jpg`;

    try {
        // 1. Verificar el archivo de video (.mp4)
        const videoExists = Deno.statSync(join(videoPath, videoFilename)).isFile;
        
        // 2. Verificar la carátula (.jpg)
        const thumbnailExists = Deno.statSync(join(videoPath, thumbnailFilename)).isFile;

        return videoExists && thumbnailExists;

    } catch (_e) {
        // Si Deno.statSync falla, significa que el archivo no existe.
        return false;
    }
}


async function generateIndexPage(rootDir) {
    const allVideoData = [];
    
    // ... (Lógica de recolección de videos: 1, 2, 3) ...
    for await (const channelEntry of Deno.readDir(VIDEOS_DIR)) {
        const channelPath = join(VIDEOS_DIR, channelEntry.name);
        
        if (channelEntry.isDirectory && 
            channelEntry.name !== '.' && 
            channelEntry.name !== '..' && 
            channelEntry.name !== 'css' && 
            channelEntry.name !== 'img' && 
            channelEntry.name !== 'stuff' &&
            channelEntry.name !== 'js' 
        ) {
            const channelName = channelEntry.name;
            
            for await (const videoEntry of Deno.readDir(channelPath)) {
                const videoPath = join(channelPath, videoEntry.name);
                
                if (videoEntry.isDirectory) {
                    const videoId = videoEntry.name;
                    const metadata = await readVideoMetadata(videoPath);
                    
                    if (metadata) {
                        const hasRequiredFiles = await checkFiles(videoPath, videoId); 

                        if (hasRequiredFiles) {
                            const videoLink = `./${channelName}/${videoId}/index.html`; 
                            const localJpgFilename = `${videoId}.jpg`; 
                            const thumbnailSource = `./${channelName}/${videoId}/${localJpgFilename}`;
                            
                            const description = (metadata.description || 'Sin descripción.').substring(0, 100) + '...';
                            const uploadDate = metadata.upload_date ? new Date(
                                parseInt(metadata.upload_date.substring(0, 4)),
                                parseInt(metadata.upload_date.substring(4, 6)) - 1,
                                parseInt(metadata.upload_date.substring(6, 8))
                            ).toLocaleDateString('es-ES') : 'N/A';

                            allVideoData.push({
                                title: metadata.title,
                                link: videoLink,
                                thumbnail: thumbnailSource,
                                description: description,
                                date: uploadDate,
                                channel: metadata.uploader || channelName
                            });
                        }
                    }
                }
            }
        }
    }

    console.log(`  ✅ Recolectados ${allVideoData.length} videos válidos para el índice.`);

    // 4. Ordenar aleatoriamente los videos recolectados
    for (let i = allVideoData.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [allVideoData[i], allVideoData[j]] = [allVideoData[j], allVideoData[i]];
    }
    
    // 5. Leer el módulo JS del menú para generar la lista estática (SEO/Yacy)
    let staticChannelListHtml = '';
    try {
        const jsFilePath = join(rootDir, 'js', "menu_data.js");
        let jsContent = await Deno.readTextFile(jsFilePath);
        jsContent = jsContent.replace('export const menuData = ', '').replace(/;$/, '');
        
        const menuData = JSON.parse(jsContent);

        const listItems = menuData.map(channel => `
            <li><a href="${channel.url}">${channel.name}</a></li>
        `).join('');

        staticChannelListHtml = `
            <section id="yacy-seo-list" style="position: absolute; left: -9999px; visibility: hidden; width: 0; height: 0; overflow: hidden;">
                <h2>Índice de Canales para Rastreadores</h2>
                <ul id="channel-list-yacy">
                    ${listItems}
                </ul>
            </section>
        `;
    } catch (e) {
        console.warn(`⚠️ Advertencia: No se pudo leer menu_data.js. No se generará la lista SEO estática. Error: ${e.message}`);
    }


    // 6. Construcción del bodyContent (CON TOP BAR)
    const bodyContent = `
        <nav id="sidebar" class="collapsed">
            <button id="toggleSidebar" title="Alternar menú">☰</button>
            <div class="sidebar-header">📚 Archivos Offline</div>
            <ul id="sidebar-content">
                <p style="padding: 10px; opacity: 0.7;">Cargando canales...</p>
            </ul>
        </nav>

        ${staticChannelListHtml} 
        
        <div id="topbar" class="topbar-controls">
            <button id="fontDecrease" class="font-control" title="Disminuir Tamaño de Fuente">A-</button> 
            <button id="fontIncrease" class="font-control" title="Aumentar Tamaño de Fuente">A+</button>
            
            <button id="themeToggle" class="theme-toggle" title="Alternar Modo Claro/Oscuro">Cambiar Tema</button>
        </div>


        <div class="main-content-wrapper">
            <div class="container" style="max-width: 100%; margin: 0; padding: 0;">

                <header class="main-header" style="padding: 20px;">
                    <h1 style="padding: 0;"><a href="./" style="text-decoration: none;">Página Principal de Contenido</a></h1>
                    <p style="padding: 0;">Mostrando ${allVideoData.length} videos de todos los canales. (Videos cargados de forma aleatoria).</p>
                </header>

                <hr style="margin: 0 20px;">
                
                <div id="videoListContainer" class="video-list-grid" style="padding: 20px;">
                </div>
                
                <div id="loadingSentinel" style="height: 10px; margin-top: 30px; text-align: center;">
                    <p id="loadingMessage">Cargando más videos...</p>
                </div>
            </div>
        </div> 
        
        <script>
            const ALL_VIDEOS_DATA = ${JSON.stringify(allVideoData)}; 
            const VIDEOS_PER_PAGE = ${VIDEOS_PER_PAGE};
        </script>
        
        <script src="./js/theme-toggle.js" defer></script>
        <script src="./js/lazy-load.js" defer></script>
        <script src="./js/font-size.js" defer></script>
        <script src="./js/menu.js" type="module" defer></script> 
    `;

    // 7. Generar la página HTML usando el wrapper
    const htmlContent = generateHtmlWrapper(
        `Índice Principal`, 
        bodyContent, 
        './css/style.css',
        [] 
    );

    await Deno.writeTextFile(join(rootDir, OUTPUT_FILENAME), htmlContent);
    console.log(`  ✅ Generado índice principal: ${join(rootDir, OUTPUT_FILENAME)}`);
}

generateIndexPage(rootDir);
