import { useEffect } from 'react';

/**
 * Hook de seguridad que muestra un mensaje de advertencia en la consola
 * para prevenir ataques de ingeniería social (Self-XSS).
 * Similar a lo que hacen Facebook, Discord, etc.
 */
export const useSeguridadConsola = () => {
    useEffect(() => {
        // Detectar si estamos en un entorno de desarrollo local
        const esLocal =
            window.location.hostname === 'localhost' ||
            window.location.hostname === '127.0.0.1' ||
            window.location.hostname.includes('.local');

        // No ejecutar en desarrollo para no molestar al desarrollador
        // COMENTADO PARA VERIFICACIÓN DEL USUARIO:
        // if (esLocal) return;

        // Función segura para mostrar el mensaje
        const mostrarAdvertencia = () => {
            try {
                // Limpiar la consola para que el mensaje destaque
                console.clear();

                // Estilos para el título grande y rojo
                const estiloTitulo = [
                    'color: #ef4444', // Red-500
                    'font-size: 40px',
                    'font-weight: bold',
                    'text-shadow: 1px 1px 2px black',
                    'padding: 10px',
                ].join(';');

                // Estilos para el texto del cuerpo
                const estiloTexto = [
                    'color: #1f2937', // Gray-800
                    'font-size: 16px',
                    'font-family: sans-serif',
                    'padding: 10px',
                    'line-height: 1.5',
                ].join(';');

                // Mostrar el mensaje
                console.log('%c¡Detente!', estiloTitulo);
                console.log(
                    '%cEsta función del navegador está pensada para desarrolladores. Si alguien te ha indicado que copies y pegues algo aquí para habilitar una función o para "hackear" la cuenta de alguien, se trata de un fraude. Si lo haces, esa persona podrá acceder a tu cuenta.',
                    estiloTexto
                );
            } catch (e) {
                // Ignorar errores de consola
            }
        };

        // Mostrar inmediatamente
        mostrarAdvertencia();

        // Opcional: Intentar prevenir que se borre
        const timeoutId = setTimeout(mostrarAdvertencia, 1000);

        // --- BLOQUEO DE INSPECTOR (Solicitado por seguridad visual) ---
        const bloquearClickDerecho = (e: MouseEvent) => {
            e.preventDefault();
        };

        const bloquearTeclasInspector = (e: KeyboardEvent) => {
            // Bloquear F12
            if (e.key === 'F12') {
                e.preventDefault();
            }
            // Bloquear Ctrl+Shift+I, Ctrl+Shift+J, Ctrl+Shift+C (Inspector)
            if (e.ctrlKey && e.shiftKey && (e.key === 'I' || e.key === 'J' || e.key === 'C' || e.key === 'i' || e.key === 'j' || e.key === 'c')) {
                e.preventDefault();
            }
            // Bloquear Ctrl+U (Ver código fuente)
            if (e.ctrlKey && (e.key === 'U' || e.key === 'u')) {
                e.preventDefault();
            }
        };

        // Agregar listeners
        document.addEventListener('contextmenu', bloquearClickDerecho);
        document.addEventListener('keydown', bloquearTeclasInspector);

        return () => {
            clearTimeout(timeoutId);
            document.removeEventListener('contextmenu', bloquearClickDerecho);
            document.removeEventListener('keydown', bloquearTeclasInspector);
        };
    }, []);
};
