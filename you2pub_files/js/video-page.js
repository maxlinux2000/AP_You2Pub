// js/video-page.js - Lógica específica para la página de visualización de video

document.addEventListener('DOMContentLoaded', () => {
    // ===========================================
    // Lógica de Player JavaScript Vanilla
    // ===========================================
    const video = document.getElementById('mainVideo');
    const backButton = document.getElementById('back30s');
    const forwardButton = document.getElementById('forward30s');
    const jump = 30; // segundos para salto

    if (video && backButton && forwardButton) {
        // 1. Play/Pause al pulsar el video
        video.addEventListener('click', (e) => {
            // Evita que el clic en los botones de control del navegador active el evento del video
            if (e.target.tagName !== 'VIDEO') return; 
            video.paused ? video.play() : video.pause();
        });

        // 2. Control de avance/retroceso con botones
        backButton.addEventListener('click', () => {
            video.currentTime = Math.max(0, video.currentTime - jump);
        });

        forwardButton.addEventListener('click', () => {
            video.currentTime += jump;
        });
        
        // 3. Atajos de teclado (Play/Pause, Jump, Fullscreen)
        document.addEventListener('keydown', (e) => {
            // No interferir con inputs de texto
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return; 

            // Space: Play/Pause
            if (e.code === 'Space') {
                e.preventDefault(); 
                video.paused ? video.play() : video.pause();
            } 
            // ArrowLeft: Atrás 30s
            else if (e.key === 'ArrowLeft') {
                e.preventDefault();
                // Simula el click del botón
                backButton.click(); 
            } 
            // ArrowRight: Adelante 30s
            else if (e.key === 'ArrowRight') {
                e.preventDefault();
                // Simula el click del botón
                forwardButton.click();
            }
            
            // F: Fullscreen
            else if (e.key === 'f' || e.key === 'F') {
                e.preventDefault();
                if (document.fullscreenElement) {
                    document.exitFullscreen();
                } else {
                    // Entrar en pantalla completa (se usa el elemento del video)
                    video.requestFullscreen();
                }
            } 
        });
    }


    // ===========================================
    // Efecto Parallax para el banner
    // ===========================================
    const bannerImage = document.querySelector('.main-banner');

    if (bannerImage) {
        // Escucha el scroll global y ajusta la posición de la imagen
        window.addEventListener('scroll', () => {
            const scroll = window.scrollY;
            // Movimiento vertical ajustado para el efecto parallax
            bannerImage.style.transform = `translate3d(0, ${scroll * 0.3}px, 0)`;
        });
    }

});
