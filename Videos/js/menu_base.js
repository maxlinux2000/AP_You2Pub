// js/menu_base.js (Lógica central con Lazy-Load por Scroll)

// Importa los datos del menú.
import { menuData } from './menu_data.js';

// --- VARIABLES DE CONTROL PARA LAZY-LOAD ---
const CHANNELS_PER_LOAD = 30; // Número de canales a cargar en cada lote
let channelsLoadedCount = 0; // Contador de cuántos canales se han cargado
let isAllChannelsLoaded = false; // Bandera para saber si ya se terminó

// ... (Resto de Logs y código de importación) ...


/**
 * Genera el HTML del menú y lo inserta en el contenedor dado.
 * @param {string} prefix - El prefijo de ruta necesario (ej: "", "../", "../../").
 * @param {string} containerId - El ID del elemento donde se insertará la lista de canales.
 */
export function renderMenu(prefix, containerId = 'sidebar-content') {
    console.log(`DEBUG: Invocando renderMenu() con prefijo: '${prefix}' en ID: ${containerId}`);
    
    const container = document.getElementById(containerId);
    if (!container) {
        console.error(`DEBUG: ❌ Contenedor '${containerId}' no encontrado. Asegúrate de que existe en el HTML.`);
        return;
    }
    console.log(`DEBUG: ✅ Contenedor '${containerId}' encontrado.`);

    // --- FUNCIONES DE LAZY-LOAD ---

    /**
     * Genera e inyecta el siguiente lote de elementos de menú.
     */
    function loadNextBatch() {
        if (isAllChannelsLoaded) {
            return;
        }

        const startIndex = channelsLoadedCount;
        const endIndex = Math.min(menuData.length, startIndex + CHANNELS_PER_LOAD);

        if (startIndex >= endIndex) {
            isAllChannelsLoaded = true;
            console.log("DEBUG: Todos los canales han sido cargados.");
            return;
        }

        let menuHtml = '';
        const currentBatch = menuData.slice(startIndex, endIndex);

        currentBatch.forEach(item => {
            const finalUrl = prefix + item.url.substring(2);
            const finalIcon = prefix + item.icon.substring(2);

            menuHtml += `
                <li><a href="${finalUrl}" class="menu-item">
                    <img src="${finalIcon}" alt="Icono de ${item.name}" class="menu-icon">
                    <span class="menu-name">${item.name}</span>
                </a></li>
            `;
        });

        // 🚨 CAMBIO CLAVE: Usamos insertAdjacentHTML('beforeend', ...) en lugar de container.innerHTML = ...
        // Esto añade los nuevos elementos al final sin borrar los existentes.
        container.insertAdjacentHTML('beforeend', menuHtml);
        
        channelsLoadedCount = endIndex;
        console.log(`DEBUG: Lote cargado. Total de canales cargados: ${channelsLoadedCount}`);

        // Si es la primera carga, borramos el "Cargando..." que estaba en el HTML estático
        if (startIndex === 0) {
            container.querySelector('p')?.remove();
        }
    }
    
    // --- 1. CARGA INICIAL (Solo el primer lote) ---
    loadNextBatch();


    // --- 2. Lógica de Interacción (Toggle y Lazy-Load) ---

    const sidebar = document.getElementById('sidebar');
    const menuToggle = document.getElementById('toggleSidebar');

    if (sidebar) {
        // Añadir el Listener de Scroll para la carga perezosa
        sidebar.addEventListener('scroll', () => {
            if (isAllChannelsLoaded) {
                return;
            }

            // Detectar si el usuario está cerca del final (ej: a 100px del fondo)
            const scrollableHeight = sidebar.scrollHeight - sidebar.clientHeight;
            const scrollPosition = sidebar.scrollTop;
            const threshold = 100; // Cargar cuando estemos a 100px del final

            if (scrollableHeight - scrollPosition < threshold) {
                loadNextBatch();
            }
        });
        console.log("DEBUG: ✅ Listener de scroll añadido a #sidebar para Lazy-Load.");
    }

    if (menuToggle && sidebar) {
        menuToggle.addEventListener('click', () => {
            const isExpanded = sidebar.classList.contains('collapsed');
            sidebar.classList.toggle('collapsed');
            console.log(`DEBUG: Sidebar clickeada. Estado: ${isExpanded ? 'ABIERTO' : 'CERRADO'}`);
        });
        console.log("DEBUG: ✅ Listener de click añadido a #toggleSidebar.");
    } else {
        console.error("DEBUG: ❌ No se pudo encontrar #toggleSidebar o #sidebar.");
    }
}

