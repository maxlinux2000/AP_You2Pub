// generate_menu.ts (VERSION CONSOLIDADA Y CORREGIDA)
// Uso: deno run --allow-read --allow-write generate_menu.ts <root_dir>
// <root_dir> debe ser el directorio que contiene los canales (ej: 'Videos').

import { join } from "https://deno.land/std@0.224.0/path/mod.ts";

// Obtenemos el directorio raíz pasado como argumento
const [rootDir] = Deno.args; 

// 🛑 Cambiamos a JS Module
const MENU_DATA_FILENAME = "menu_data.js"; 
// Ruta completa donde se guardará: <rootDir>/js/menu_data.js
const MENU_DATA_PATH = join(rootDir, 'js', MENU_DATA_FILENAME); 

if (!rootDir) {
    console.error("Falta la ruta al directorio raíz (ej: ~/public_html/You2Pub).");
    Deno.exit(1);
}

// Interfaz de datos
interface ChannelData {
    name: string; // Nombre del canal (ej: "Canal_A")
    url: string;  // Ruta relativa al index.html del canal (ej: "./Canal_A/index.html")
    icon: string; // Ruta relativa al icono del canal (ej: "./Canal_A/img/icon.png")
}

/**
 * Genera el contenido de un archivo JS que exporta los datos.
 * @param channels Array de objetos ChannelData.
 * @returns String con el contenido del módulo JS.
 */
function generateJsModule(channels: ChannelData[]): string {
    const jsonContent = JSON.stringify(channels, null, 4);
    // Exportamos la constante para ser importada por menu.js
    return `export const menuData = ${jsonContent};`;
}

/**
 * Función principal para escanear directorios y generar el archivo de datos.
 * @param rootDir El directorio principal que contiene todos los canales.
 */
async function generateMenuFiles(rootDir: string) {
    const allChannelData: ChannelData[] = [];
    
    // Lista de nombres de directorios a ignorar
    const IGNORED_DIRS = new Set(['.', '..', 'css', 'img', 'stuff', 'js']);
 
    console.log(`Buscando canales en el directorio: ${rootDir}`);

    try {
        // Leemos el contenido del directorio raíz
        for await (const channelEntry of Deno.readDir(rootDir)) {
            
            // Si es un directorio y no es una carpeta de utilidades o especial
            if (channelEntry.isDirectory && !IGNORED_DIRS.has(channelEntry.name)) {
                
                const channelName = channelEntry.name;
                
                // Las rutas relativas se construyen A PARTIR DEL DIRECTORIO RAÍZ (donde está el index.html principal)
                
                // 1. Ruta del enlace: debe apuntar al index.html dentro del subdirectorio del canal
                // Ejemplo: Si rootDir es 'Videos', y channelName es 'Canal_X', la URL es './Canal_X/index.html'
                const relativeUrl = `./${channelName}/index.html`;
                
                // 2. Ruta del icono: debe apuntar al icono dentro de la carpeta img del subdirectorio del canal
                // Ejemplo: './Canal_X/img/icon.png'
                const iconPath = `./${channelName}/img/icon.png`; 
                
                allChannelData.push({
                    name: channelName,
                    url: relativeUrl,
                    icon: iconPath,
                });
            }
        }
        
        console.log(`✅ Recolectados ${allChannelData.length} canales para el menú.`);

        // 2. Asegurarse de que el directorio /js exista dentro de rootDir
        const jsDir = join(rootDir, 'js');
        await Deno.mkdir(jsDir, { recursive: true });

        // 3. Generar y guardar menu_data.js
        const jsContent = generateJsModule(allChannelData);
        await Deno.writeTextFile(MENU_DATA_PATH, jsContent);
        console.log(`✅ Generado módulo JS de datos de menú: ${MENU_DATA_PATH}`);

    } catch (e) {
        // En caso de error (ej: permisos de lectura/escritura o ruta inexistente)
        console.error(`\n❌ ERROR al generar archivos de menú:`);
        console.error(`   Asegúrate de que la ruta '${rootDir}' existe y tienes permisos.`);
        console.error(`   Detalle del error: ${e.message}`);
        Deno.exit(1);
    }
}

generateMenuFiles(rootDir);
