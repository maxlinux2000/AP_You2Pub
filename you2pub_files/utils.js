// utils.js

import { join } from "https://deno.land/std@0.224.0/path/mod.ts";

/**
 * Lee y parsea el archivo info.json en la carpeta del video.
 * @param {string} videoPath - Ruta a la carpeta del video (ej: Videos/Canal/20251010_ID)
 * @returns {object|null}
 */
export async function readVideoMetadata(videoPath) {
    try {
        const jsonFiles = [];
        for await (const entry of Deno.readDir(videoPath)) {
            if (entry.name.endsWith('.info.json')) {
                jsonFiles.push(entry.name);
            }
        }
        if (jsonFiles.length === 0) return null;

        const jsonFilePath = join(videoPath, jsonFiles[0]);
        const jsonContent = await Deno.readTextFile(jsonFilePath);
        return JSON.parse(jsonContent);

    } catch (e) {
        // console.error(`Error leyendo metadatos en ${videoPath}: ${e.message}`);
        return null;
    }
}

/**
 * Genera la plantilla HTML base (Cabecera, estilos, scripts, etc.)
 * @param {string} title - Título para la página
 * @param {string} bodyContent - Contenido principal inyectado
 * @param {string} cssPath - Ruta relativa al archivo CSS
 * @param {string[]} [scriptList=[]] - Array de rutas relativas a los archivos JS
 * @returns {string}
 */
export function generateHtmlWrapper(title, bodyContent, cssPath, scriptList = []) {
    
    // 1. Convertir la lista de rutas de scripts en etiquetas <script>
    const scriptTags = scriptList.map(scriptPath => 
        `<script src="${scriptPath}" defer></script>`
    ).join('\n    '); // Unir las etiquetas con un salto de línea y tabulación para legibilidad

    return `
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <link rel="stylesheet" href="${cssPath}">
</head>
<body>
    <div class="container">
        <!-- El contenido principal del body no está envuelto en <h1> ni <a> aquí. 
             generate_root.js ya maneja su propia estructura de encabezado. -->
        ${bodyContent}
    </div>
    
    <!-- Scripts cargados por generateHtmlWrapper -->
    ${scriptTags} 

</body>
</html>
`;
}