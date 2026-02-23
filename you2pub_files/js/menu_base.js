/**
 * menu_base.js
 * Lógica central para cargar y renderizar el menú lateral.
 */

console.log("--- DEBUG: Cargando menu_base.js ---");

/**
 * Renderiza el menú lateral cargando los datos desde menu_data.json
 * @param {string} prefix - Prefijo de ruta (ej: './' o '../')
 * @param {string} containerId - ID del contenedor <ul>
 */
export async function renderMenu(prefix = './', containerId = 'sidebar-content') {
    const container = document.getElementById(containerId);
    
    if (!container) {
        console.error(`DEBUG: ❌ No se encontró el contenedor #${containerId}`);
        return;
    }

    try {
        // Construimos la ruta al JSON de forma relativa para evitar errores de dominio
        const jsonUrl = `${prefix}js/menu_data.json`;
        console.log(`DEBUG: Intentando cargar menú desde: ${jsonUrl}`);

        const response = await fetch(jsonUrl);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const channels = await response.json();
        console.log(`DEBUG: ✅ ${channels.length} canales cargados.`);

        let menuHtml = '';

        channels.forEach(item => {
            // El JSON contiene el nombre de la carpeta en 'folder'
            const folder = item.folder;
            
            // Construimos rutas relativas basadas en el prefijo
            const finalUrl = `${prefix}${folder}/index.html`;
            const finalIcon = `${prefix}${folder}/img/icon.png`;

            menuHtml += `
                <li>
                    <a href="${finalUrl}" class="menu-item">
                        <img src="${finalIcon}" alt="${folder}" class="menu-icon" 
                             onerror="this.src='${prefix}js/default-icon.png';">
                        <span class="menu-name">${folder}</span>
                    </a>
                </li>
            `;
        });

        container.innerHTML = menuHtml;

    } catch (error) {
        console.error("DEBUG: ❌ Error cargando el menú:", error);
        container.innerHTML = `<li style="padding:10px; color:red;">Error cargando menú</li>`;
    }

    // --- Lógica del botón Toggle ---
    const sidebar = document.getElementById('sidebar');
    const menuToggle = document.getElementById('toggleSidebar');

    if (menuToggle && sidebar) {
        // Eliminamos listeners previos para evitar duplicados
        menuToggle.onclick = () => {
            sidebar.classList.toggle('collapsed');
            console.log("DEBUG: Sidebar toggle clickeado");
        };
    }
}
