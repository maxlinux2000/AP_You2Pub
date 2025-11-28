// js/menu.js (VERSION CONSOLIDADA)
// 🛑 Importamos los datos del módulo JS generado por generate_menu.ts
import { menuData } from '../js/menu_data.js';

document.addEventListener('DOMContentLoaded', () => {
    
    const sidebar = document.getElementById('sidebar');
    const toggleButton = document.getElementById('toggleSidebar');
    const sidebarContent = document.getElementById('sidebar-content');

    // Comprobaciones omitidas para simplificar
    
    // ==================================
    // 1. Renderizado del Menú (A partir de la variable importada)
    // ==================================
    
    function renderMenu(data) {
        if (!data || data.length === 0) {
            sidebarContent.innerHTML = '<li>No hay canales disponibles.</li>';
            return;
        }

        // 🛑 Limpiar mensaje de carga
        sidebarContent.innerHTML = ''; 
        
        let channelHtml = `
            <li class="sidebar-item home-link">
                <a href="./">🏠 Inicio / Todos los Videos</a>
            </li>
            <hr class="separator-item">
        `;
        
        // Ordenar y renderizar
        data.sort((a, b) => a.name.localeCompare(b.name)).forEach(channel => {
            channelHtml += `
                <li class="sidebar-item">
                    <a href="${channel.url}" title="Ver canal: ${channel.name}">
                        <img src="${channel.icon}" alt="Icono de ${channel.name}" style="width: 20px; height: 20px; margin-right: 5px; border-radius: 50%; object-fit: cover;">
                        <span class="channel-name-full">${channel.name}</span>
                    </a>
                </li>
            `;
        });
        
        sidebarContent.innerHTML = channelHtml;
    }
    
    // ==================================
    // 2. Lógica del Toggle (Persistencia)
    // ==================================
    
    const isCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
    if (isCollapsed) {
        sidebar.classList.add('collapsed');
        toggleButton.textContent = '▶'; 
    } else {
        toggleButton.textContent = '◀';
    }

    toggleButton.addEventListener('click', () => {
        const currentlyCollapsed = sidebar.classList.toggle('collapsed');
        localStorage.setItem('sidebarCollapsed', currentlyCollapsed);
        toggleButton.textContent = currentlyCollapsed ? '▶' : '◀';
    });

    // 🛑 Iniciar el renderizado con los datos importados
    renderMenu(menuData);
});

