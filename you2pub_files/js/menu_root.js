// menu_root.js (Cargado por /index.html)

import { renderMenu } from './menu_base.js'; // Ambos están en /js/

document.addEventListener('DOMContentLoaded', () => {
    // Prefijo './' para rutas de primer nivel
    renderMenu('./'); 
});
