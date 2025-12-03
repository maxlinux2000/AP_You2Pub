// js/font-size.js (VERSION CORREGIDA)

document.addEventListener('DOMContentLoaded', () => {
    const root = document.documentElement; // Es el elemento <html>
    const increaseButton = document.getElementById('fontIncrease');
    const decreaseButton = document.getElementById('fontDecrease');
    const STORAGE_KEY = 'fontSizeScale';
    
    const MIN_SIZE = 10;
    const MAX_SIZE = 36;
    const STEP = 2; // Ajustar en pasos de 2px
    
    // Almacenamos el tamaño actual en una variable JS para rastrearlo.
    // Inicializamos con el valor guardado o el valor por defecto.
    let currentSize = parseInt(localStorage.getItem(STORAGE_KEY));
    if (isNaN(currentSize)) {
        currentSize = 16; // Tamaño por defecto
    }

    // Función para aplicar el tamaño de fuente y actualizar el almacenamiento
    function applyFontSize(size) {
        // Asegura que el tamaño esté dentro de los límites
        const newSize = Math.min(MAX_SIZE, Math.max(MIN_SIZE, size));
        
        // 🛑 Importante: Actualiza la variable de rastreo en JS
        currentSize = newSize; 
        
        // Aplica el tamaño a la variable CSS --font-scale-base
        root.style.setProperty('--font-scale-base', `${newSize}px`);
        
        // Guarda en localStorage
        localStorage.setItem(STORAGE_KEY, newSize);
    }

    // 1. Cargar y aplicar tamaño guardado al inicio
    applyFontSize(currentSize);


    // 2. Evento Aumentar Fuente
    if (increaseButton) {
        increaseButton.addEventListener('click', () => {
            // Usamos la variable de rastreo 'currentSize' que siempre es un número
            applyFontSize(currentSize + STEP);
        });
    }

    // 3. Evento Disminuir Fuente
    if (decreaseButton) {
        decreaseButton.addEventListener('click', () => {
            // Usamos la variable de rastreo 'currentSize'
            applyFontSize(currentSize - STEP);
        });
    }
});
