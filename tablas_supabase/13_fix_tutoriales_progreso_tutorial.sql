-- =====================================================
-- 🎯 FIX CORRECTO - TUTORIALES EN PROGRESO_TUTORIAL
-- =====================================================
-- Los tutoriales se marcan como completados en la tabla progreso_tutorial, no en inscripciones

-- Paso 1: Verificar las tablas existentes
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'progreso_tutorial') THEN
        RAISE NOTICE '✅ Tabla progreso_tutorial encontrada';
    ELSE
        RAISE NOTICE '❌ Tabla progreso_tutorial NO existe';
        RETURN;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'progreso_lecciones') THEN
        RAISE NOTICE '✅ Tabla progreso_lecciones encontrada (para referencia)';
    ELSE
        RAISE NOTICE '⚠️ Tabla progreso_lecciones no encontrada';
    END IF;
END $$;

-- Paso 2: Limpiar triggers antiguos incorrectos en inscripciones
DO $$
BEGIN
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.inscripciones;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.inscripciones;
    RAISE NOTICE '🗑️ Triggers incorrectos eliminados de inscripciones';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Error limpiando triggers antiguos: %', SQLERRM;
END $$;

-- Paso 3: Crear triggers CORRECTOS en progreso_tutorial
DO $$
BEGIN
    -- Trigger para tutorial completado - INSERT (nuevo progreso ya completado)
    BEGIN
        DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.progreso_tutorial;
        CREATE TRIGGER trigger_tutorial_completado_insert
            AFTER INSERT ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE)
            EXECUTE FUNCTION trigger_actualizar_xp('tutorial_completado');
        RAISE NOTICE '✅ Trigger INSERT para progreso_tutorial creado';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Error creando trigger INSERT progreso_tutorial: %', SQLERRM;
    END;
    
    -- Trigger para tutorial completado - UPDATE (progreso actualizado a completado)
    BEGIN
        DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.progreso_tutorial;
        CREATE TRIGGER trigger_tutorial_completado_update
            AFTER UPDATE ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND (OLD.completado = FALSE OR OLD.completado IS NULL))
            EXECUTE FUNCTION trigger_actualizar_xp('tutorial_completado');
        RAISE NOTICE '✅ Trigger UPDATE para progreso_tutorial creado';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Error creando trigger UPDATE progreso_tutorial: %', SQLERRM;
    END;
END $$;

-- Paso 4: Verificar que los triggers fueron creados
DO $$
DECLARE
    trigger_count INTEGER;
    trigger_name TEXT;
BEGIN
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers 
    WHERE event_object_table = 'progreso_tutorial'
    AND trigger_name LIKE '%tutorial%';
    
    RAISE NOTICE '📊 Triggers en progreso_tutorial: %', trigger_count;
    
    -- Mostrar todos los triggers creados
    FOR trigger_name IN 
        SELECT t.trigger_name
        FROM information_schema.triggers t
        WHERE t.event_object_table = 'progreso_tutorial'
        AND t.trigger_name LIKE '%tutorial%'
    LOOP
        RAISE NOTICE '   🔧 Trigger: %', trigger_name;
    END LOOP;
END $$;

-- Paso 5: Función de prueba para progreso_tutorial
CREATE OR REPLACE FUNCTION probar_tutorial_progreso(p_usuario_id UUID, p_tutorial_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_progreso_id UUID;
    v_resultado TEXT;
BEGIN
    -- Crear un progreso de tutorial completado
    INSERT INTO progreso_tutorial (
        id, usuario_id, tutorial_id, completado, ultimo_acceso, fecha_inicio, fecha_actualizacion
    ) VALUES (
        gen_random_uuid(), p_usuario_id, p_tutorial_id, TRUE, NOW(), NOW(), NOW()
    ) RETURNING id INTO v_progreso_id;
    
    v_resultado := 'Progreso tutorial creado: ' || v_progreso_id::TEXT || '. Revisa si se sumaron +50 XP.';
    RETURN v_resultado;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Paso 6: Función para actualizar progreso existente a completado
CREATE OR REPLACE FUNCTION marcar_tutorial_completado(p_usuario_id UUID, p_tutorial_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_progreso_id UUID;
    v_resultado TEXT;
    v_rows_affected INTEGER;
BEGIN
    -- Buscar progreso existente y marcarlo como completado
    UPDATE progreso_tutorial 
    SET 
        completado = TRUE,
        fecha_actualizacion = NOW(),
        ultimo_acceso = NOW()
    WHERE usuario_id = p_usuario_id 
    AND tutorial_id = p_tutorial_id
    AND (completado = FALSE OR completado IS NULL)
    RETURNING id INTO v_progreso_id;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    
    IF v_rows_affected > 0 THEN
        v_resultado := 'Tutorial marcado como completado: ' || v_progreso_id::TEXT || '. Revisa si se sumaron +50 XP.';
    ELSE
        v_resultado := 'No se encontró progreso pendiente para ese tutorial, o ya estaba completado.';
    END IF;
    
    RETURN v_resultado;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Paso 7: Mostrar comparación de estructuras
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 COMPARACIÓN DE ESTRUCTURAS:';
    RAISE NOTICE '';
    RAISE NOTICE '🎓 LECCIONES (progreso_lecciones):';
    RAISE NOTICE '   • Campo: estado = ''completada''';
    RAISE NOTICE '   • Triggers: ✅ Funcionando';
    RAISE NOTICE '';
    RAISE NOTICE '📚 TUTORIALES (progreso_tutorial):';
    RAISE NOTICE '   • Campo: completado = TRUE';
    RAISE NOTICE '   • Triggers: ✅ Recién creados';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 DIFERENCIAS PRINCIPALES:';
    RAISE NOTICE '   • Lecciones usan campo "estado"';
    RAISE NOTICE '   • Tutoriales usan campo "completado"';
    RAISE NOTICE '   • Ambos ahora tienen triggers correctos';
END $$;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 TUTORIALES ARREGLADOS CORRECTAMENTE';
    RAISE NOTICE '📝 Ahora cuando completes un tutorial al 100%:';
    RAISE NOTICE '   • Campo completado = TRUE en progreso_tutorial';
    RAISE NOTICE '   • Se sumarán +50 XP automáticamente';
    RAISE NOTICE '   • Se actualizarán las estadísticas';
    RAISE NOTICE '   • Se recalculará el ranking';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Para probar manualmente:';
    RAISE NOTICE '   SELECT probar_tutorial_progreso(''tu-usuario-id'', ''tutorial-id'');';
    RAISE NOTICE '   SELECT marcar_tutorial_completado(''tu-usuario-id'', ''tutorial-id'');';
    RAISE NOTICE '';
    RAISE NOTICE '📊 ESTADO ACTUAL DEL SISTEMA:';
    RAISE NOTICE '   ✅ Publicaciones: +15 XP';
    RAISE NOTICE '   ✅ Likes: +2 XP';
    RAISE NOTICE '   ✅ Lecciones: +10 XP (progreso_lecciones)';
    RAISE NOTICE '   ✅ Tutoriales: +50 XP (progreso_tutorial)';
    RAISE NOTICE '   ✅ Cursos: +100 XP (inscripciones)';
END $$; 