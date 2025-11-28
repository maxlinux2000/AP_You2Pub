 // js/lazy-load.js


document.addEventListener('DOMContentLoaded', () => {

    // Estas variables están definidas en el script de datos de index.html:

    // const ALL_VIDEOS_DATA = [...];

    // const VIDEOS_PER_PAGE = 50;


    if (typeof ALL_VIDEOS_DATA === 'undefined') {

        console.error("ALL_VIDEOS_DATA no está definido. Asegúrate de que generate_root.js lo incluye.");

        return;

    }


    let currentIndex = 0;

    const container = document.getElementById('videoListContainer');

    const sentinel = document.getElementById('loadingSentinel');

    const loadingMessage = document.getElementById('loadingMessage');

    

    if (!container || !sentinel) return;


    // ==========================================

    // Funciones de Dibujo y Lazy Loading

    // ==========================================

    

    function createVideoElement(video) {

        const item = document.createElement('div');

        item.className = 'video-item';

        // Nota: Asegúrate que las rutas 'video.link' y 'video.thumbnail' sean correctas.

        item.innerHTML = `

            <a href="${video.link}">

                <img src="${video.thumbnail}" alt="${video.title}" loading="lazy">

            </a>

            <div class="video-item-content">

                <h3><a href="${video.link}">${video.title}</a></h3>

                <p class="channel-name-text">Canal: ${video.channel}</p>

                <p class="description-text">${video.description}</p>

                <p class="date-text">Subido el: ${video.date}</p>

            </div>

        `;

        return item;

    }


    function loadMoreVideos() {

        const startIndex = currentIndex;

        const endIndex = Math.min(currentIndex + VIDEOS_PER_PAGE, ALL_VIDEOS_DATA.length);

        

        if (startIndex >= ALL_VIDEOS_DATA.length) {

            loadingMessage.textContent = "Fin de la lista de videos.";

            // Detener la observación

            if (typeof observer !== 'undefined') {

                observer.unobserve(sentinel);

            }

            return;

        }

        

        loadingMessage.textContent = "Cargando...";


        const fragment = document.createDocumentFragment();

        for (let i = startIndex; i < endIndex; i++) {

            fragment.appendChild(createVideoElement(ALL_VIDEOS_DATA[i]));

        }

        container.appendChild(fragment);

        

        currentIndex = endIndex;

        

        if (currentIndex < ALL_VIDEOS_DATA.length) {

            loadingMessage.textContent = "Cargando más videos...";

        } else {

            loadingMessage.textContent = "Fin de la lista de videos.";

            if (typeof observer !== 'undefined') {

                observer.unobserve(sentinel);

            }

        }

    }


    // Intersection Observer para detectar el final de la página

    const observer = new IntersectionObserver((entries) => {

        entries.forEach(entry => {

            if (entry.isIntersecting) {

                loadMoreVideos();

            }

        });

    }, {

        rootMargin: '100px' // Cargar cuando estemos a 100px del final

    });


    // Cargar la primera página inmediatamente

    loadMoreVideos();

    // Configuramos el observador

    observer.observe(sentinel);

}); 
