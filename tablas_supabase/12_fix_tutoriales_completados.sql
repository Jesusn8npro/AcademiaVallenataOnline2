-- =====================================================
-- 🎯 FIX TUTORIALES COMPLETADOS - TRIGGERS FALTANTES
-- =====================================================
-- Agrega los triggers que faltaron para que funcionen los tutoriales completados

-- Paso 1: Verificar que existe la tabla inscripciones
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inscripciones') THEN
        RAISE NOTICE '✅ Tabla inscripciones encontrada';
    ELSE
        RAISE NOTICE '❌ Tabla inscripciones NO existe';
        RETURN;
    END IF;
END $$;

-- Paso 2: Crear triggers para tutoriales completados
DO $$
BEGIN
    -- Trigger para tutorial completado - INSERT (nuevo tutorial marcado como completado)
    BEGIN
        DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.inscripciones;
        CREATE TRIGGER trigger_tutorial_completado_insert
            AFTER INSERT ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.tutorial_id IS NOT NULL)
            EXECUTE FUNCTION trigger_actualizar_xp('tutorial_completado');
        RAISE NOTICE '✅ Trigger INSERT para tutoriales completados creado';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Error creando trigger INSERT tutoriales: %', SQLERRM;
    END;
    
    -- Trigger para tutorial completado - UPDATE (tutorial actualizado a completado)
    BEGIN
        DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.inscripciones;
        CREATE TRIGGER trigger_tutorial_completado_update
            AFTER UPDATE ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND OLD.completado = FALSE AND NEW.tutorial_id IS NOT NULL)
            EXECUTE FUNCTION trigger_actualizar_xp('tutorial_completado');
        RAISE NOTICE '✅ Trigger UPDATE para tutoriales completados creado';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Error creando trigger UPDATE tutoriales: %', SQLERRM;
    END;
END $$;

-- Paso 3: Crear triggers para cursos completados (por si no existen)
DO $$
BEGIN
    -- Trigger para curso completado - INSERT
    BEGIN
        DROP TRIGGER IF EXISTS trigger_curso_completado_insert ON public.inscripciones;
        CREATE TRIGGER trigger_curso_completado_insert
            AFTER INSERT ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.curso_id IS NOT NULL)
            EXECUTE FUNCTION trigger_actualizar_xp('curso_completado');
        RAISE NOTICE '✅ Trigger INSERT para cursos completados creado';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Error creando trigger INSERT cursos: %', SQLERRM;
    END;
    
    -- Trigger para curso completado - UPDATE
    BEGIN
        DROP TRIGGER IF EXISTS trigger_curso_completado_update ON public.inscripciones;
        CREATE TRIGGER trigger_curso_completado_update
            AFTER UPDATE ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND OLD.completado = FALSE AND NEW.curso_id IS NOT NULL)
            EXECUTE FUNCTION trigger_actualizar_xp('curso_completado');
        RAISE NOTICE '✅ Trigger UPDATE para cursos completados creado';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Error creando trigger UPDATE cursos: %', SQLERRM;
    END;
END $$;

-- Paso 4: Verificar que los triggers fueron creados
DO $$
DECLARE
    trigger_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers 
    WHERE event_object_table = 'inscripciones'
    AND trigger_name LIKE '%tutorial%' OR trigger_name LIKE '%curso%';
    
    RAISE NOTICE '📊 Total de triggers en inscripciones: %', trigger_count;
    
    -- Mostrar todos los triggers creados
    FOR trigger_count IN 
        SELECT 1 FROM information_schema.triggers 
        WHERE event_object_table = 'inscripciones'
        AND (trigger_name LIKE '%tutorial%' OR trigger_name LIKE '%curso%')
    LOOP
        NULL;
    END LOOP;
END $$;

-- Paso 5: Función para probar manualmente los triggers
CREATE OR REPLACE FUNCTION probar_tutorial_completado(p_usuario_id UUID, p_tutorial_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_inscripcion_id UUID;
    v_resultado TEXT;
BEGIN
    -- Crear una inscripción de prueba
    INSERT INTO inscripciones (
        id, usuario_id, tutorial_id, completado, fecha_inscripcion, created_at, updated_at
    ) VALUES (
        gen_random_uuid(), p_usuario_id, p_tutorial_id, TRUE, NOW(), NOW(), NOW()
    ) RETURNING id INTO v_inscripcion_id;
    
    v_resultado := 'Inscripción creada: ' || v_inscripcion_id::TEXT || '. Revisa si se sumaron +50 XP.';
    RETURN v_resultado;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '🎯 TRIGGERS PARA TUTORIALES COMPLETADOS AGREGADOS';
    RAISE NOTICE '📝 Ahora cuando marques un tutorial como completado:';
    RAISE NOTICE '   • Se sumarán +50 XP automáticamente';
    RAISE NOTICE '   • Se actualizarán las estadísticas';
    RAISE NOTICE '   • Se recalculará el ranking';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Para probar manualmente, usa:';
    RAISE NOTICE '   SELECT probar_tutorial_completado(''tu-usuario-id'', ''algun-tutorial-id'');';
END $$; 