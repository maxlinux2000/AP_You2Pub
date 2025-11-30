// menu_base.js (Lógica central compartida y manejo de interacción, con logs)

// 🚨 LOG 1: Comprobamos si el script base se está ejecutando.
//console.log("--- DEBUG: Ejecutando menu_base.js ---");

// Importa los datos del menú. Si esto falla, el código de renderizado no se ejecutará.
import { menuData } from './menu_data.js';

// 🚨 LOG 2: Comprobamos si los datos del menú se han cargado.
//if (menuData && menuData.length > 0) {
//    console.log(`DEBUG: ✅ Datos de menú cargados correctamente. ${menuData.length} canales encontrados.`);
//    console.log("DEBUG: Primer canal:", menuData[0].name);
//} else {
//    console.error("DEBUG: ❌ ERROR: menuData está vacío o no se pudo cargar.");
//}


// menu_base.js (Lógica central compartida y manejo de interacción, USANDO sidebar-content)


/**
 * Genera el HTML del menú y lo inserta en el contenedor dado.
 * El valor por defecto se cambia a 'sidebar-content'
 * @param {string} prefix - El prefijo de ruta necesario (ej: "", "../", "../../").
 * @param {string} containerId - El ID del elemento donde se insertará la lista de canales.
 */
export function renderMenu(prefix, containerId = 'sidebar-content') { // 👈 CAMBIO AQUÍ
    // 🚨 LOG 3: Comprobamos el prefijo recibido.
    console.log(`DEBUG: Invocando renderMenu() con prefijo: '${prefix}' en ID: ${containerId}`);
    
    const container = document.getElementById(containerId);
    if (!container) {
        console.error(`DEBUG: ❌ Contenedor '${containerId}' no encontrado. Asegúrate de que existe en el HTML.`);
        return;
    }
    console.log(`DEBUG: ✅ Contenedor '${containerId}' encontrado.`);

    // --- 1. Generación del HTML de la lista de canales (NO del botón hamburguesa) ---
    
    let menuHtml = '';

    // El botón de hamburguesa ya existe en el HTML como #toggleSidebar. 
    // Solo inyectamos la lista de enlaces en #sidebar-content.
    
    menuData.forEach(item => {
        const finalUrl = prefix + item.url.substring(2);
        const finalIcon = prefix + item.icon.substring(2);

        // ... (Log de ejemplo) ...

        // Usamos <li> o <a> directamente dependiendo de la estructura de #sidebar-content
        // Como #sidebar-content es un <ul>, inyectamos <li>:
        menuHtml += `
            <li><a href="${finalUrl}" class="menu-item">
                <img src="${finalIcon}" alt="Icono de ${item.name}" class="menu-icon">
                <span class="menu-name">${item.name}</span>
            </a></li>
        `;
    });

    // Reemplazamos el contenido de "Cargando canales..."
    container.innerHTML = menuHtml;

    console.log("DEBUG: ✅ Lista de canales inyectada en el contenedor.");


    // --- 2. Lógica de Interacción (Toggle del Menú Lateral) ---

    // El botón de toggle ya es #toggleSidebar en tu HTML.
    // El elemento a colapsar es la misma #sidebar.
    const sidebar = document.getElementById('sidebar');
    const menuToggle = document.getElementById('toggleSidebar');

    if (menuToggle && sidebar) {
        menuToggle.addEventListener('click', () => {
            const isExpanded = sidebar.classList.contains('collapsed');
            
            // Alterna el estado visual
            sidebar.classList.toggle('collapsed');

            console.log(`DEBUG: Sidebar clickeada. Estado: ${isExpanded ? 'ABIERTO' : 'CERRADO'}`);
        });
        console.log("DEBUG: ✅ Listener de click añadido a #toggleSidebar.");
    } else {
        console.error("DEBUG: ❌ No se pudo encontrar #toggleSidebar o #sidebar.");
    }
}
// El resto del código de menu_base.js se mantiene igual.