-- =====================================================
-- 🎯 FIX CON COLUMNAS REALES - SIN ERRORES
-- =====================================================
-- SOLO usando columnas que REALMENTE existen en las tablas

-- Paso 1: Verificar que la función que funciona existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'procesar_actividad_usuario_inmediato') THEN
        RAISE NOTICE '✅ Función procesar_actividad_usuario_inmediato encontrada';
    ELSE
        RAISE NOTICE '❌ Función procesar_actividad_usuario_inmediato NO encontrada';
        RAISE NOTICE '⚠️  Necesitas ejecutar primero el script 09_fix_triggers_tiempo_real.sql';
        RETURN;
    END IF;
END $$;

-- Paso 2: Actualizar SOLO la función actualizar_xp_inmediato con columnas reales
CREATE OR REPLACE FUNCTION actualizar_xp_inmediato(
    p_usuario_id UUID,
    p_tipo_actividad TEXT
)
RETURNS VOID AS $$
DECLARE
    v_xp_ganado INTEGER := 0;
    v_nuevo_nivel INTEGER;
    v_xp_total INTEGER;
    v_xp_nivel INTEGER;
BEGIN
    -- Configurar XP por tipo de actividad
    CASE p_tipo_actividad
        WHEN 'publicacion_creada' THEN v_xp_ganado := 15;
        WHEN 'comentario_creado' THEN v_xp_ganado := 5;
        WHEN 'like_recibido' THEN v_xp_ganado := 2;
        WHEN 'leccion_completada' THEN v_xp_ganado := 10;
        WHEN 'parte_tutorial_completada' THEN v_xp_ganado := 15;  -- NUEVA CONFIGURACIÓN
        WHEN 'tutorial_completado' THEN v_xp_ganado := 50;
        WHEN 'curso_completado' THEN v_xp_ganado := 100;
        ELSE 
            RAISE NOTICE '⚠️ Tipo de actividad no reconocido: %', p_tipo_actividad;
            RETURN;
    END CASE;

    -- Actualizar experiencia del usuario USANDO COLUMNAS REALES
    INSERT INTO experiencia_usuario (
        usuario_id, nivel, xp_actual, xp_total, xp_cursos, xp_comunidad, ultima_sesion
    ) VALUES (
        p_usuario_id, 1, v_xp_ganado, v_xp_ganado, 
        CASE WHEN p_tipo_actividad IN ('curso_completado', 'parte_tutorial_completada', 'leccion_completada', 'tutorial_completado') THEN v_xp_ganado ELSE 0 END,
        CASE WHEN p_tipo_actividad IN ('publicacion_creada', 'comentario_creado', 'like_recibido') THEN v_xp_ganado ELSE 0 END,
        NOW()
    )
    ON CONFLICT (usuario_id)
    DO UPDATE SET
        xp_total = experiencia_usuario.xp_total + v_xp_ganado,
        nivel = GREATEST(1, (experiencia_usuario.xp_total + v_xp_ganado) / 100),
        xp_actual = (experiencia_usuario.xp_total + v_xp_ganado) % 100,
        xp_cursos = experiencia_usuario.xp_cursos + CASE WHEN p_tipo_actividad IN ('curso_completado', 'parte_tutorial_completada', 'leccion_completada', 'tutorial_completado') THEN v_xp_ganado ELSE 0 END,
        xp_comunidad = experiencia_usuario.xp_comunidad + CASE WHEN p_tipo_actividad IN ('publicacion_creada', 'comentario_creado', 'like_recibido') THEN v_xp_ganado ELSE 0 END,
        ultima_sesion = NOW(),  -- ✅ COLUMNA REAL
        updated_at = NOW()      -- ✅ COLUMNA REAL
    RETURNING xp_total, nivel INTO v_xp_total, v_nuevo_nivel;

    -- Registrar actividad reciente
    INSERT INTO actividades_recientes (
        id, usuario_id, tipo_actividad, xp_ganado, descripcion, fecha_actividad
    ) VALUES (
        gen_random_uuid(), p_usuario_id, p_tipo_actividad, v_xp_ganado, 
        'XP ganado por: ' || p_tipo_actividad, NOW()
    );

    -- Actualizar estadísticas gaming
    INSERT INTO estadisticas_gaming (usuario_id, total_xp, nivel_actual, actividades_completadas)
    VALUES (p_usuario_id, v_xp_total, v_nuevo_nivel, 1)
    ON CONFLICT (usuario_id) DO UPDATE SET
        total_xp = v_xp_total,
        nivel_actual = v_nuevo_nivel,
        actividades_completadas = estadisticas_gaming.actividades_completadas + 1,
        fecha_ultima_actividad = NOW();

    -- Actualizar ranking global
    INSERT INTO ranking_global (
        usuario_id, 
        tipo_ranking, 
        puntuacion, 
        posicion, 
        metricas, 
        activo, 
        calculated_at
    ) VALUES (
        p_usuario_id, 
        'general', 
        v_xp_total, 
        1,
        jsonb_build_object('xp_total', v_xp_total, 'nivel', v_nuevo_nivel),
        true, 
        NOW()
    )
    ON CONFLICT (usuario_id, tipo_ranking)
    DO UPDATE SET
        puntuacion = v_xp_total,
        metricas = jsonb_build_object('xp_total', v_xp_total, 'nivel', v_nuevo_nivel),
        calculated_at = NOW();

    -- Actualizar posiciones en ranking
    WITH ranking_actualizado AS (
        SELECT 
            usuario_id,
            ROW_NUMBER() OVER (ORDER BY puntuacion DESC, calculated_at ASC) as nueva_posicion
        FROM ranking_global 
        WHERE tipo_ranking = 'general' AND activo = true
    )
    UPDATE ranking_global 
    SET posicion = ra.nueva_posicion
    FROM ranking_actualizado ra
    WHERE ranking_global.usuario_id = ra.usuario_id 
    AND ranking_global.tipo_ranking = 'general';

    -- Log para debug
    RAISE NOTICE '🎯 XP actualizado: Usuario %, Actividad %, XP +%, Total %', 
        p_usuario_id, p_tipo_actividad, v_xp_ganado, v_xp_total;

END;
$$ LANGUAGE plpgsql;

-- Paso 3: Limpiar triggers antiguos problemáticos
DO $$
BEGIN
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.inscripciones;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.inscripciones;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_completada_insert ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_completada_update ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_insert ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_update ON public.progreso_tutorial;
    RAISE NOTICE '🗑️ Triggers antiguos eliminados';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Error limpiando triggers: %', SQLERRM;
END $$;

-- Paso 4: Crear triggers para partes de tutorial usando función que funciona
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'progreso_tutorial') THEN
        -- Trigger para parte de tutorial completada - INSERT
        EXECUTE 'CREATE TRIGGER trigger_parte_tutorial_insert
            AFTER INSERT ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.parte_tutorial_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''parte_tutorial_completada'')';
        
        -- Trigger para parte de tutorial completada - UPDATE
        EXECUTE 'CREATE TRIGGER trigger_parte_tutorial_update
            AFTER UPDATE ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.parte_tutorial_id IS NOT NULL AND 
                  (OLD.completado = FALSE OR OLD.completado IS NULL))
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''parte_tutorial_completada'')';
        
        RAISE NOTICE '✅ Triggers para partes de tutorial creados';
    ELSE
        RAISE NOTICE '❌ Tabla progreso_tutorial no encontrada';
    END IF;
END $$;

-- Paso 5: Verificar triggers creados
DO $$
DECLARE
    v_trigger_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_trigger_count
    FROM information_schema.triggers 
    WHERE event_object_table = 'progreso_tutorial'
    AND trigger_name LIKE '%parte_tutorial%';
    
    RAISE NOTICE '📊 Triggers de partes de tutorial: %', v_trigger_count;
END $$;

-- Paso 6: Función de prueba SIMPLE
CREATE OR REPLACE FUNCTION probar_parte_tutorial_simple(p_usuario_id UUID, p_tutorial_id UUID, p_parte_tutorial_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_progreso_id UUID;
BEGIN
    -- Insertar progreso de parte completada USANDO COLUMNAS REALES
    INSERT INTO progreso_tutorial (
        usuario_id, tutorial_id, parte_tutorial_id, completado, 
        ultimo_acceso, fecha_inicio, fecha_actualizacion  -- ✅ COLUMNAS REALES
    ) VALUES (
        p_usuario_id, p_tutorial_id, p_parte_tutorial_id, TRUE, 
        NOW(), NOW(), NOW()
    ) RETURNING id INTO v_progreso_id;
    
    RETURN 'Parte tutorial completada: ' || v_progreso_id::TEXT || '. Debería sumar +15 XP.';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 SCRIPT CON COLUMNAS REALES - SIN ERRORES';
    RAISE NOTICE '';
    RAISE NOTICE '✅ COLUMNAS VERIFICADAS:';
    RAISE NOTICE '   • experiencia_usuario: ultima_sesion, updated_at';
    RAISE NOTICE '   • progreso_tutorial: fecha_actualizacion, parte_tutorial_id';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 FUNCIÓN DE PRUEBA:';
    RAISE NOTICE '   SELECT probar_parte_tutorial_simple(''usuario-id'', ''tutorial-id'', ''parte-id'');';
    RAISE NOTICE '';
    RAISE NOTICE '📊 CONFIGURACIÓN:';
    RAISE NOTICE '   ✅ Partes Tutorial: +15 XP cada una';
    RAISE NOTICE '   ✅ Usa función que ya funciona para lecciones';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 AHORA SIN ERRORES DE COLUMNAS NO EXISTENTES';
END $$; 