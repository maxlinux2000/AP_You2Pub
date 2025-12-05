// js/search.js

document.addEventListener('DOMContentLoaded', () => {
    // Estas variables globales se definen en index.html/channel.html (en el <script> generado por Deno)
    // ALL_VIDEOS_DATA: Array de todos los objetos de video
    // VIDEOS_PER_PAGE: Número de videos a cargar por página

    const searchInput = document.getElementById('searchInput');
    const videoListContainer = document.getElementById('videoListContainer');
    const loadingSentinel = document.getElementById('loadingSentinel');
    const videoCountMessage = document.getElementById('videoCountMessage');

    // Estado de la búsqueda
    let isSearching = false;
    let filteredData = [];
    
    // Función de búsqueda
    function filterVideos(searchTerm) {
        // Normalizar término de búsqueda (minúsculas, eliminar espacios extra)
        const normalizedTerm = searchTerm.trim().toLowerCase();

        if (normalizedTerm.length === 0) {
            // Si el campo está vacío, volvemos al modo de carga normal
            isSearching = false;
            return ALL_VIDEOS_DATA;
        }

        isSearching = true;

        // Filtrar la matriz ALL_VIDEOS_DATA
        return ALL_VIDEOS_DATA.filter(video => {
            const title = video.title.toLowerCase();
            const channel = video.channel.toLowerCase();
            const description = video.fullDescription.toLowerCase(); // Usamos la descripción completa

            // Buscamos coincidencias en Título, Canal o Descripción
            return title.includes(normalizedTerm) || 
                   channel.includes(normalizedTerm) || 
                   description.includes(normalizedTerm);
        });
    }

    // ----------------------------------------------
    // 1. Manejar la entrada de búsqueda (keypress)
    // ----------------------------------------------
    searchInput.addEventListener('input', () => {
        const searchTerm = searchInput.value;
        filteredData = filterVideos(searchTerm);

        // Actualizar el mensaje de contador
        if (videoCountMessage) {
            if (isSearching) {
                videoCountMessage.textContent = `Mostrando ${filteredData.length} resultados para "${searchTerm}".`;
            } else {
                // Volver al mensaje original (asume que existe la variable global ALL_VIDEOS_DATA)
                videoCountMessage.textContent = `Mostrando ${ALL_VIDEOS_DATA.length} videos de todos los canales. (Videos cargados de forma aleatoria).`;
            }
        }

        // 2. Limpiar el contenedor actual
        videoListContainer.innerHTML = '';

        // 3. Reiniciar el índice de carga perezosa
        // NOTA: Usamos una función global que se define en lazy-load.js
        if (typeof resetLazyLoad === 'function') {
            resetLazyLoad();
        }

        // 4. Iniciar la carga de los resultados filtrados/normales
        // NOTA: Usamos una función global que se define en lazy-load.js
        if (typeof loadNextVideos === 'function') {
            // Pasamos los datos filtrados/normales como argumento
            loadNextVideos(filteredData);
        }

        // 5. Ocultar o mostrar el centinela/mensaje de carga
        if (loadingSentinel) {
             // Ocultamos el centinela si estamos en búsqueda y ya tenemos todos los resultados
            if (isSearching) {
                const resultsAreComplete = filteredData.length <= VIDEOS_PER_PAGE;
                loadingSentinel.style.display = resultsAreComplete ? 'none' : 'block';
                // Si hay más videos de los que caben en la primera página, el IntersectionObserver
                // definido en lazy-load.js lo cargará.
            } else {
                // En modo normal, siempre mostramos el centinela para la carga infinita
                loadingSentinel.style.display = 'block';
            }
        }
    });

    // ----------------------------------------------
    // 2. Integración con Lazy-Load (Modificación)
    // ----------------------------------------------
    
    // Necesitamos modificar lazy-load.js para que:
    // a) La función `loadNextVideos` acepte un array de datos.
    // b) El IntersectionObserver llame a `loadNextVideos` con el array correcto (filtrado o normal).

    // Si estás listo, podemos hacer la adaptación de lazy-load.js.
});
