// js/theme-toggle.js

document.addEventListener('DOMContentLoaded', () => {
    const themeToggle = document.getElementById('themeToggle');

    function applyTheme(isDark) {
        if (isDark) {
            document.body.classList.add('dark-mode');
            themeToggle.textContent = 'Cambiar a Light';
            localStorage.setItem('theme', 'dark');
        } else {
            document.body.classList.remove('dark-mode');
            themeToggle.textContent = 'Cambiar a Dark';
            localStorage.setItem('theme', 'light');
        }
    }

    // 1. Cargar tema guardado o preferido del sistema
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
        applyTheme(true);
    } else if (savedTheme === 'light') {
        applyTheme(false);
    } else {
        // Usar preferencia del sistema por defecto
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            applyTheme(true);
        } else {
            applyTheme(false);
        }
    }

    // 2. Evento del botón
    themeToggle.addEventListener('click', () => {
        const isDark = document.body.classList.contains('dark-mode');
        applyTheme(!isDark);
    });
});

