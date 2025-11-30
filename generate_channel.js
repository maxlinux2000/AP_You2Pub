// generate_channel.js
// Uso: deno run --allow-read --allow-write generate_channel.js <channel_path>

import { join, basename } from "https://deno.land/std@0.211.0/path/mod.ts";
import { readVideoMetadata, generateHtmlWrapper } from './utils.js';

const [channelPath] = Deno.args;
const OUTPUT_FILENAME = "index.html";

if (!channelPath) {
    console.error("Falta la ruta al directorio del canal.");
    Deno.exit(1);
}

// 💡 Parámetro de paginación
const VIDEOS_PER_PAGE = 30; // Cantidad de videos a cargar inicialmente y por bloque.

// 🎯 FUNCIÓN PRINCIPAL MODIFICADA
async function generateChannelPage(channelPath) {
    const channelName = basename(channelPath);
    // Usaremos un Map para acceder rápidamente a los datos por ID de carpeta
    const videoMap = new Map(); 
    let channelTitle = channelName;
    let channelDescription = "Sin descripción."; // Variable para descripción del canal
    
    // ===========================================
    // 1. LEER LA LISTA ORDENADA DE IDs (Si existe)
    // ===========================================
    const idsFilePath = join(channelPath, 'video_ids_for_download.txt');
    let orderedIds = [];
    try {
        const content = await Deno.readTextFile(idsFilePath);
        // Filtramos líneas vacías y separamos por nueva línea
        orderedIds = content.split('\n').map(id => id.trim()).filter(id => id.length > 0);
        console.log(`   📝 Encontrados ${orderedIds.length} IDs para la ordenación.`);
    } catch (_e) {
        console.warn(`   ⚠️ Archivo de ordenación '${idsFilePath}' no encontrado. Se usará la ordenación alfabética por defecto.`);
    }
    
    // ===========================================
    // 2. Recorrer las carpetas y recolectar los datos en el Mapa
    // ===========================================
    // Intentar leer info.json del canal para la descripción/título del banner
    try {
        const channelInfoPath = join(channelPath, 'channel.info.json');
        const channelInfo = JSON.parse(await Deno.readTextFile(channelInfoPath));
        channelTitle = channelInfo.channel || channelName;
        channelDescription = channelInfo.description || channelDescription;
    } catch (_e) {
        console.warn("   ⚠️ No se pudo leer 'channel.info.json'. Usando valores por defecto.");
    }
    
    for await (const entry of Deno.readDir(channelPath)) {
        const videoPath = join(channelPath, entry.name);
        // Verifica que sea un directorio y que no sea 'img', 'css', etc.
        if (entry.isDirectory && entry.name !== '.' && entry.name !== '..' && entry.name !== 'img' && entry.name !== 'css' && entry.name !== 'js') {
            const metadata = await readVideoMetadata(videoPath);
            
            if (metadata) {
                // Capturamos el ID de la carpeta, que es el ID de YouTube
                const videoId = entry.name; 
                
                // Intento de encontrar la miniatura local
                const localJpgFilename = `${videoId}.jpg`; 
                let thumbnailSource = metadata.thumbnail; 

                try {
                    const localJpgPath = join(videoPath, localJpgFilename);
                    if (Deno.statSync(localJpgPath).isFile) {
                        thumbnailSource = `./${videoId}/${localJpgFilename}`;
                    } else {
                         for await (const fileEntry of Deno.readDir(videoPath)) {
                             if (fileEntry.name.endsWith('.jpg') || fileEntry.name.endsWith('.webp')) {
                                 thumbnailSource = `./${videoId}/${fileEntry.name}`;
                                 break;
                             }
                         }
                    }
                } catch (_e) {
                    thumbnailSource = thumbnailSource || 'placeholder.png';
                }

                // Obtener descripción y fecha en formato legible
                const videoLink = `./${videoId}/${OUTPUT_FILENAME}`;
                // Asegurar que la descripción no sea nula antes de intentar el substring
                const description = (metadata.description || 'Sin descripción.').substring(0, 100) + '...';
                const uploadDate = metadata.upload_date ? new Date(
                    parseInt(metadata.upload_date.substring(0, 4)),
                    parseInt(metadata.upload_date.substring(4, 6)) - 1,
                    parseInt(metadata.upload_date.substring(6, 8))
                ).toLocaleDateString('es-ES') : 'N/A';

                // Almacenar en el mapa
                videoMap.set(videoId, {
                    title: metadata.title,
                    link: videoLink,
                    thumbnail: thumbnailSource,
                    // Se añade el nombre del canal aquí, aunque no se usa en la tarjeta, es buena práctica
                    channel: channelTitle, 
                    description: description,
                    date: uploadDate,
                    id: videoId
                });
            }
        }
    }
    
    // ===========================================
    // 3. CONSTRUIR EL ARRAY FINAL DE DATOS ORDENADO
    // ===========================================
    let videoData = [];
    
    if (orderedIds.length > 0) {
        // Usar el orden de IDs del archivo
        for (const id of orderedIds) {
            const data = videoMap.get(id);
            if (data) {
                videoData.push(data);
                videoMap.delete(id); 
            }
        }
        // Si quedan IDs que no estaban en el archivo, añadirlos al final
        videoData = videoData.concat(Array.from(videoMap.values()).sort((a, b) => a.title.localeCompare(b.title)));
        
    } else {
        // Si no hay archivo de IDs, usar la ordenación alfabética de carpetas como fallback
        videoData = Array.from(videoMap.values()).sort((a, b) => a.title.localeCompare(b.title));
    }


    // 4. Generar el contenido HTML
    // ===========================================
    // 🛑 NUEVA LÓGICA DE DETECCIÓN DE IMÁGENES
    // ===========================================
    const IMG_DIR = join(channelPath, 'img');
    let BANNER_PATH = './img/placeholder-banner.jpg'; // Valor por defecto
    let ICON_PATH = './img/placeholder-icon.png';    // Valor por defecto

    try {
        for await (const fileEntry of Deno.readDir(IMG_DIR)) {
            const filename = fileEntry.name;
            
            // Error 2: Detectar el Icono (icon.png)
            if (filename.toLowerCase() === 'icon.png') {
                ICON_PATH = `./img/${filename}`;
            }
            
            // Error 3: Detectar el Banner (banner_<nombre-canal>.jpg)
            // Ya que solo hay dos imágenes, podemos ser flexibles y buscar cualquier banner
            if (filename.startsWith('banner_') && (filename.endsWith('.jpg') || filename.endsWith('.jpeg'))) {
                BANNER_PATH = `./img/${filename}`;
            }
        }
    } catch (e) {
        console.warn(`   ⚠️ No se pudo leer la carpeta 'img' en ${channelName}. Usando placeholders.`);
    }

    const OUTPUT_FILENAME_VIDEO = "index.html";

    const bodyContent = `
        <div id="topbar" class="topbar-controls">
            <button id="fontDecrease" class="font-control" title="Disminuir Tamaño de Fuente">A-</button> 
            <button id="fontIncrease" class="font-control" title="Aumentar Tamaño de Fuente">A+</button>
            <button id="themeToggle" class="theme-toggle" title="Alternar Modo Claro/Oscuro">
                Cambiar Tema
            </button>
            <a href="../index.html" class="home-button-banner" title="Volver a la Página Principal">
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
            <div class="banner-container-channel">
                <img src="${BANNER_PATH}" alt="Banner del Canal ${channelTitle}" class="main-banner"/>
            </div>

            <div class="channel-header">
                <img src="${ICON_PATH}" alt="Icono de ${channelTitle}" class="channel-icon-large">
                <h1>${channelTitle}</h1>
                <p class="channel-description">${channelDescription}</p>
            </div>

            <h2>Videos del Canal (${videoData.length} videos)</h2>
            
            <div id="videoListContainer" class="video-list-grid">
            </div>

            <div id="loadingSentinel" style="height: 10px; margin-top: 30px; text-align: center;">
                <p id="loadingMessage" style="color: var(--text-primary);">Cargando más videos...</p>
            </div>
        </div>
        
        <div style="display:none;">
            <h2>Todos los Videos de ${channelTitle}</h2>
            ${videoData.map(video => `<a href="./${video.id}/${OUTPUT_FILENAME_VIDEO}">${video.title}</a>`).join('\n')}
        </div>
        
        <script>
            // ==========================================
            // 🎯 DATOS DE LA PÁGINA (NECESARIOS INLINE)
            // Estos datos son usados por lazy-load.js y menu.js.
            // ==========================================
            const ALL_VIDEOS_DATA = ${JSON.stringify(videoData)};
            const VIDEOS_PER_PAGE = ${VIDEOS_PER_PAGE};
        </script>

        <script src="../js/theme-toggle.js" defer></script> 
        <script src="../js/lazy-load.js" defer></script>
        <script src="../js/font-size.js" defer></script>
        <script src="../js/menu_channel.js" type="module" defer></script>
`;

    // 5. Generar la página HTML completa
    // La ruta relativa al CSS es '../css/style.css'
    const CSS_PATH = '../css/style.css'; 

    const htmlContent = generateHtmlWrapper(`Canal: ${channelTitle}`, bodyContent, CSS_PATH);
    await Deno.writeTextFile(join(channelPath, OUTPUT_FILENAME), htmlContent);
    console.log(`  ✅ Generado índice de canal: ${channelPath}`);
}

generateChannelPage(channelPath);
