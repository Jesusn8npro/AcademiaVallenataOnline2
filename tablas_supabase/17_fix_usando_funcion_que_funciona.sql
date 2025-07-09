-- =====================================================
-- 🎯 FIX USANDO LA FUNCIÓN QUE SÍ FUNCIONA
-- =====================================================
-- Usar la misma función que funciona para lecciones: procesar_actividad_usuario_inmediato()

-- Paso 1: Verificar que la función que funciona existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'procesar_actividad_usuario_inmediato') THEN
        RAISE NOTICE '✅ Función procesar_actividad_usuario_inmediato encontrada (la que funciona)';
    ELSE
        RAISE NOTICE '❌ Función procesar_actividad_usuario_inmediato NO encontrada';
        RAISE NOTICE '⚠️  Necesitas ejecutar primero el script 09_fix_triggers_tiempo_real.sql';
        RETURN;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'actualizar_xp_inmediato') THEN
        RAISE NOTICE '✅ Función actualizar_xp_inmediato encontrada (la que funciona)';
    ELSE
        RAISE NOTICE '❌ Función actualizar_xp_inmediato NO encontrada';
        RAISE NOTICE '⚠️  Necesitas ejecutar primero el script 09_fix_triggers_tiempo_real.sql';
        RETURN;
    END IF;
END $$;

-- Paso 2: Actualizar la función actualizar_xp_inmediato para soportar parte_tutorial_completada
DO $$
BEGIN
    -- Leer el contenido actual de la función
    RAISE NOTICE '📝 Actualizando función actualizar_xp_inmediato para soportar partes de tutorial';
END $$;

CREATE OR REPLACE FUNCTION actualizar_xp_inmediato(
    p_usuario_id UUID,
    p_tipo_actividad TEXT
)
RETURNS VOID AS $$
DECLARE
    v_xp_ganado INTEGER := 0;
    v_nuevo_nivel INTEGER;
    v_xp_total INTEGER;
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

    -- Actualizar experiencia del usuario
    INSERT INTO experiencia_usuario (usuario_id, xp_total, nivel, fecha_ultima_actividad)
    VALUES (p_usuario_id, v_xp_ganado, 1, NOW())
    ON CONFLICT (usuario_id)
    DO UPDATE SET
        xp_total = experiencia_usuario.xp_total + v_xp_ganado,
        nivel = LEAST(10, ((experiencia_usuario.xp_total + v_xp_ganado) / 100) + 1),
        xp_cursos = experiencia_usuario.xp_cursos + CASE WHEN p_tipo_actividad IN ('curso_completado', 'parte_tutorial_completada', 'leccion_completada', 'tutorial_completado') THEN v_xp_ganado ELSE 0 END,
        xp_comunidad = experiencia_usuario.xp_comunidad + CASE WHEN p_tipo_actividad IN ('publicacion_creada', 'comentario_creado', 'like_recibido') THEN v_xp_ganado ELSE 0 END,
        ultima_sesion = NOW(),
        updated_at = NOW()
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
        1, -- Se actualizará después
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
    -- Limpiar todos los triggers antiguos relacionados con tutoriales
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.inscripciones;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.inscripciones;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_completada_insert ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_completada_update ON public.progreso_tutorial;
    RAISE NOTICE '🗑️ Triggers antiguos problemáticos eliminados';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Error limpiando triggers antiguos: %', SQLERRM;
END $$;

-- Paso 4: Crear triggers para partes de tutorial usando la función que SÍ funciona
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'progreso_tutorial') THEN
        -- Trigger para parte de tutorial completada - INSERT
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_parte_tutorial_insert ON public.progreso_tutorial';
        EXECUTE 'CREATE TRIGGER trigger_parte_tutorial_insert
            AFTER INSERT ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.parte_tutorial_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''parte_tutorial_completada'')';
        
        -- Trigger para parte de tutorial completada - UPDATE
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_parte_tutorial_update ON public.progreso_tutorial';
        EXECUTE 'CREATE TRIGGER trigger_parte_tutorial_update
            AFTER UPDATE ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.parte_tutorial_id IS NOT NULL AND 
                  (OLD.completado = FALSE OR OLD.completado IS NULL))
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''parte_tutorial_completada'')';
        
        RAISE NOTICE '✅ Triggers para partes de tutorial creados usando función que funciona';
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
    
    RAISE NOTICE '📊 Triggers de partes de tutorial creados: %', v_trigger_count;
END $$;

-- Paso 6: Función de prueba para parte de tutorial
CREATE OR REPLACE FUNCTION probar_parte_tutorial_15xp(p_usuario_id UUID, p_tutorial_id UUID, p_parte_tutorial_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_progreso_id UUID;
BEGIN
    -- Crear progreso de parte completada
    INSERT INTO progreso_tutorial (
        usuario_id, tutorial_id, parte_tutorial_id, completado, 
        ultimo_acceso, fecha_inicio, fecha_actualizacion
    ) VALUES (
        p_usuario_id, p_tutorial_id, p_parte_tutorial_id, TRUE, 
        NOW(), NOW(), NOW()
    ) RETURNING id INTO v_progreso_id;
    
    RETURN 'Parte tutorial completada: ' || v_progreso_id::TEXT || '. Debería sumar +15 XP automáticamente.';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Paso 7: Función para completar parte existente
CREATE OR REPLACE FUNCTION completar_parte_tutorial_15xp(p_usuario_id UUID, p_parte_tutorial_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_rows INTEGER;
    v_tutorial_id UUID;
BEGIN
    -- Obtener tutorial_id de la parte
    SELECT tutorial_id INTO v_tutorial_id
    FROM partes_tutorial
    WHERE id = p_parte_tutorial_id;
    
    IF v_tutorial_id IS NULL THEN
        RETURN 'Error: Parte de tutorial no encontrada';
    END IF;
    
    -- Actualizar progreso existente
    UPDATE progreso_tutorial 
    SET 
        completado = TRUE,
        fecha_actualizacion = NOW(),
        ultimo_acceso = NOW()
    WHERE usuario_id = p_usuario_id 
    AND parte_tutorial_id = p_parte_tutorial_id
    AND (completado = FALSE OR completado IS NULL);
    
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    
    IF v_rows > 0 THEN
        RETURN 'Parte marcada como completada. Debería sumar +15 XP automáticamente.';
    ELSE
        RETURN 'No se encontró progreso pendiente o ya estaba completada.';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 PARTES DE TUTORIAL ARREGLADAS CON FUNCIÓN QUE FUNCIONA';
    RAISE NOTICE '';
    RAISE NOTICE '✅ AHORA USA LA MISMA FUNCIÓN QUE LAS LECCIONES:';
    RAISE NOTICE '   • procesar_actividad_usuario_inmediato()';
    RAISE NOTICE '   • actualizar_xp_inmediato() (actualizada)';
    RAISE NOTICE '   • Cada parte de tutorial = +15 XP';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 FUNCIONES DE PRUEBA:';
    RAISE NOTICE '   SELECT probar_parte_tutorial_15xp(''usuario-id'', ''tutorial-id'', ''parte-id'');';
    RAISE NOTICE '   SELECT completar_parte_tutorial_15xp(''usuario-id'', ''parte-id'');';
    RAISE NOTICE '';
    RAISE NOTICE '📊 SISTEMA GAMING UNIFICADO:';
    RAISE NOTICE '   ✅ Publicaciones: +15 XP';
    RAISE NOTICE '   ✅ Comentarios: +5 XP';
    RAISE NOTICE '   ✅ Likes: +2 XP';
    RAISE NOTICE '   ✅ Lecciones: +10 XP';
    RAISE NOTICE '   ✅ Partes Tutorial: +15 XP (ARREGLADO)';
    RAISE NOTICE '   ✅ Tutoriales: +50 XP';
    RAISE NOTICE '   ✅ Cursos: +100 XP';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 AHORA DEBERÍA FUNCIONAR IGUAL QUE LAS LECCIONES';
END $$; 