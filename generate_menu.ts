// generate_menu.ts (VERSION CONSOLIDADA)
// Uso: deno run --allow-read --allow-write generate_menu.ts <root_dir>

import { join } from "https://deno.land/std@0.211.0/path/mod.ts";

const [rootDir] = Deno.args;
// 🛑 Cambiamos a JS Module
const MENU_DATA_FILENAME = "menu_data.js"; 
const MENU_DATA_PATH = join(rootDir, 'js', MENU_DATA_FILENAME); // Lo guardaremos en /js

if (!rootDir) {
    console.error("Falta la ruta al directorio raíz (ej: Videos).");
    Deno.exit(1);
}

// Interfaz de datos
interface ChannelData {
    name: string;
    url: string;
    icon: string;
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

async function generateMenuFiles(rootDir: string) {
    const allChannelData: ChannelData[] = [];
    
    try {
        // ... (Tu lógica para recolectar canales, la mantendremos) ...
        for await (const channelEntry of Deno.readDir(rootDir)) {
            const channelPath = join(rootDir, channelEntry.name);
            
            // Solo procesar directorios que no sean carpetas de utilidades
            if (channelEntry.isDirectory && 
                channelEntry.name !== '.' && 
                channelEntry.name !== '..' && 
                channelEntry.name !== 'css' && 
                channelEntry.name !== 'img' && 
                channelEntry.name !== 'stuff' &&
                channelEntry.name !== 'js' // Aseguramos que la carpeta JS no se trate como canal
            ) {
                const channelName = channelEntry.name;
                
                // Ruta del enlace para la Home/Root
                const relativeUrl = `./${channelName}/index.html`;
                
                // Ruta del icono (asumiendo que está en el directorio del canal)
                const iconPath = `./${channelName}/img/icon.png`; 
                
                allChannelData.push({
                    name: channelName,
                    url: relativeUrl,
                    icon: iconPath,
                });
            }
        }
        
        console.log(`  ✅ Recolectados ${allChannelData.length} canales para el menú.`);

        // 2. Asegurarse de que el directorio /js exista
        await Deno.mkdir(join(rootDir, 'js'), { recursive: true });

        // 3. Generar y guardar menu_data.js
        const jsContent = generateJsModule(allChannelData);
        await Deno.writeTextFile(MENU_DATA_PATH, jsContent);
        console.log(`  ✅ Generado módulo JS de datos de menú: ${MENU_DATA_PATH}`);

    } catch (e) {
        console.error(`ERROR al generar archivos de menú: ${e}`);
        Deno.exit(1);
    }
}

generateMenuFiles(rootDir);

