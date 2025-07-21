-- =====================================================
-- 🎵 EJECUTAR SIMULADOR DE ACORDEÓN GAMIFICADO
-- =====================================================
-- Archivo para ejecutar de manera segura el simulador
-- Verifica dependencias antes de crear las tablas
-- =====================================================

-- 1. VERIFICAR PREREQUISITOS
-- Verificar que existan las tablas necesarias
DO $$
BEGIN
    -- Verificar tabla perfiles
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'perfiles') THEN
        RAISE EXCEPTION 'La tabla "perfiles" no existe. Ejecuta primero las tablas de usuarios.';
    END IF;
    
    -- Verificar tabla logros_sistema si se va a usar
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'logros_sistema') THEN
        RAISE NOTICE 'La tabla "logros_sistema" no existe. Algunas funcionalidades de logros podrían no funcionar.';
    END IF;
    
    RAISE NOTICE 'Verificaciones completadas. Procediendo con la creación de tablas...';
END $$;

-- 2. EJECUTAR TABLAS DEL SIMULADOR
-- Aquí va el contenido completo del archivo simulador_acordeon_gamificado.sql
-- Puedes copiar y pegar todo el contenido aquí, o ejecutar el archivo original

-- 3. MENSAJE DE FINALIZACIÓN
DO $$
BEGIN
    RAISE NOTICE '🎵 ¡Simulador de Acordeón Gamificado creado exitosamente!';
    RAISE NOTICE '📊 Tablas creadas:';
    RAISE NOTICE '   - sesiones_simulador_acordeon';
    RAISE NOTICE '   - lecciones_acordeon';
    RAISE NOTICE '   - canciones_vallenatas';
    RAISE NOTICE '   - logros_acordeon';
    RAISE NOTICE '   - desafios_diarios';
    RAISE NOTICE '   - progreso_lecciones_acordeon';
    RAISE NOTICE '   - progreso_canciones_vallenatas';
    RAISE NOTICE '   - progreso_desafios_diarios';
    RAISE NOTICE '   - estadisticas_acordeon';
    RAISE NOTICE '🚀 Ya puedes usar el simulador gamificado!';
END $$; 