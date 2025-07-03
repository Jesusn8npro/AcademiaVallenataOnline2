-- 🎯 FASE 1.3 - ACTUALIZAR TABLA PERFILES 
-- Script para mejorar la tabla perfiles con campos de membresía
-- Academia Vallenata Online - Sistema de Suscripciones

-- ====================================
-- 1️⃣ AGREGAR NUEVOS CAMPOS A PERFILES
-- ====================================

-- Campos relacionados con membresías
ALTER TABLE perfiles 
ADD COLUMN IF NOT EXISTS membresia_activa_id UUID REFERENCES membresias(id),
ADD COLUMN IF NOT EXISTS fecha_inicio_membresia DATE,
ADD COLUMN IF NOT EXISTS fecha_vencimiento_membresia DATE,
ADD COLUMN IF NOT EXISTS notificaciones_membresia BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS preferencias_membresia JSONB DEFAULT '{}'::jsonb;

-- Campos para experiencia de usuario
ALTER TABLE perfiles 
ADD COLUMN IF NOT EXISTS primera_vez BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS onboarding_completado BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS ultima_actividad TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS racha_dias INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS puntos_experiencia INTEGER DEFAULT 0;

-- Campos para configuración de simulador
ALTER TABLE perfiles 
ADD COLUMN IF NOT EXISTS configuracion_simulador JSONB DEFAULT '{
    "volumen": 50,
    "velocidad_metronomo": 120,
    "tono_favorito": "DO",
    "modo_practica": "libre",
    "mostrar_notas": true,
    "grabacion_automatica": false
}'::jsonb;

-- Campos para preferencias de contenido
ALTER TABLE perfiles 
ADD COLUMN IF NOT EXISTS preferencias_contenido JSONB DEFAULT '{
    "generos_favoritos": [],
    "artistas_favoritos": [],
    "nivel_preferido": "intermedio",
    "notificaciones_nuevos_cursos": true,
    "notificaciones_nuevos_tutoriales": true,
    "notificaciones_eventos": true
}'::jsonb;

-- Campos para gamificación
ALTER TABLE perfiles 
ADD COLUMN IF NOT EXISTS logros_obtenidos JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS insignias JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS nivel_usuario INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS experiencia_total INTEGER DEFAULT 0;

-- ====================================
-- 2️⃣ CREAR ÍNDICES PARA OPTIMIZACIÓN
-- ====================================

-- Índice para membresía activa
CREATE INDEX IF NOT EXISTS idx_perfiles_membresia_activa 
    ON perfiles(membresia_activa_id) 
    WHERE membresia_activa_id IS NOT NULL;

-- Índice para usuarios activos
CREATE INDEX IF NOT EXISTS idx_perfiles_ultima_actividad 
    ON perfiles(ultima_actividad DESC);

-- Índice para ranking por experiencia
CREATE INDEX IF NOT EXISTS idx_perfiles_experiencia_ranking 
    ON perfiles(experiencia_total DESC, nivel_usuario DESC);

-- Índice para búsqueda por suscripción
CREATE INDEX IF NOT EXISTS idx_perfiles_suscripcion_estado 
    ON perfiles(suscripcion, fecha_vencimiento_membresia);

-- ====================================
-- 3️⃣ FUNCIÓN PARA SINCRONIZAR MEMBRESÍA
-- ====================================

CREATE OR REPLACE FUNCTION sincronizar_membresia_perfil(p_usuario_id UUID)
RETURNS VOID AS $$
DECLARE
    membresia_info RECORD;
BEGIN
    -- Obtener información de la membresía activa
    SELECT 
        su.membresia_id,
        su.fecha_inicio,
        su.fecha_vencimiento,
        m.nombre as membresia_nombre
    INTO membresia_info
    FROM suscripciones_usuario su
    JOIN membresias m ON su.membresia_id = m.id
    WHERE su.usuario_id = p_usuario_id 
      AND su.estado = 'activa'
      AND su.fecha_vencimiento >= CURRENT_DATE
    ORDER BY su.fecha_vencimiento DESC
    LIMIT 1;
    
    -- Actualizar perfil con información de membresía
    IF membresia_info.membresia_id IS NOT NULL THEN
        UPDATE perfiles SET
            membresia_activa_id = membresia_info.membresia_id,
            fecha_inicio_membresia = membresia_info.fecha_inicio,
            fecha_vencimiento_membresia = membresia_info.fecha_vencimiento,
            suscripcion = membresia_info.membresia_nombre,
            updated_at = NOW()
        WHERE user_id = p_usuario_id;
    ELSE
        -- Si no tiene membresía activa, limpiar campos
        UPDATE perfiles SET
            membresia_activa_id = NULL,
            fecha_inicio_membresia = NULL,
            fecha_vencimiento_membresia = NULL,
            suscripcion = 'free',
            updated_at = NOW()
        WHERE user_id = p_usuario_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 4️⃣ FUNCIÓN PARA ACTUALIZAR EXPERIENCIA
-- ====================================

CREATE OR REPLACE FUNCTION agregar_experiencia(
    p_usuario_id UUID, 
    p_puntos INTEGER,
    p_accion TEXT DEFAULT 'actividad_general'
) RETURNS JSONB AS $$
DECLARE
    perfil_actual RECORD;
    nuevo_nivel INTEGER;
    logro_desbloqueado TEXT;
    resultado JSONB;
BEGIN
    -- Obtener perfil actual
    SELECT 
        puntos_experiencia,
        experiencia_total,
        nivel_usuario,
        logros_obtenidos
    INTO perfil_actual
    FROM perfiles 
    WHERE user_id = p_usuario_id;
    
    IF perfil_actual IS NULL THEN
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;
    
    -- Calcular nuevo nivel basado en experiencia total
    nuevo_nivel := FLOOR((perfil_actual.experiencia_total + p_puntos) / 1000) + 1;
    
    -- Determinar si se desbloqueó un logro
    logro_desbloqueado := NULL;
    IF nuevo_nivel > perfil_actual.nivel_usuario THEN
        logro_desbloqueado := 'nivel_' || nuevo_nivel::text;
    END IF;
    
    -- Actualizar experiencia en el perfil
    UPDATE perfiles SET
        puntos_experiencia = puntos_experiencia + p_puntos,
        experiencia_total = experiencia_total + p_puntos,
        nivel_usuario = nuevo_nivel,
        logros_obtenidos = CASE 
            WHEN logro_desbloqueado IS NOT NULL THEN
                logros_obtenidos || jsonb_build_array(jsonb_build_object(
                    'id', logro_desbloqueado,
                    'nombre', 'Nivel ' || nuevo_nivel,
                    'descripcion', 'Alcanzaste el nivel ' || nuevo_nivel,
                    'fecha_obtenido', NOW(),
                    'puntos_otorgados', p_puntos
                ))
            ELSE logros_obtenidos
        END,
        ultima_actividad = NOW(),
        updated_at = NOW()
    WHERE user_id = p_usuario_id;
    
    -- Preparar respuesta
    resultado := jsonb_build_object(
        'puntos_agregados', p_puntos,
        'experiencia_total', perfil_actual.experiencia_total + p_puntos,
        'nivel_anterior', perfil_actual.nivel_usuario,
        'nivel_actual', nuevo_nivel,
        'subio_nivel', nuevo_nivel > perfil_actual.nivel_usuario,
        'logro_desbloqueado', logro_desbloqueado
    );
    
    RETURN resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 5️⃣ FUNCIÓN PARA ACTUALIZAR RACHA
-- ====================================

CREATE OR REPLACE FUNCTION actualizar_racha_usuario(p_usuario_id UUID)
RETURNS INTEGER AS $$
DECLARE
    dias_racha INTEGER := 0;
    ultima_act DATE;
BEGIN
    -- Obtener última actividad
    SELECT DATE(ultima_actividad) INTO ultima_act
    FROM perfiles 
    WHERE user_id = p_usuario_id;
    
    IF ultima_act IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Calcular racha
    IF ultima_act = CURRENT_DATE THEN
        -- Ya registró actividad hoy, mantener racha actual
        SELECT racha_dias INTO dias_racha FROM perfiles WHERE user_id = p_usuario_id;
    ELSIF ultima_act = CURRENT_DATE - INTERVAL '1 day' THEN
        -- Actividad ayer, incrementar racha
        UPDATE perfiles SET 
            racha_dias = racha_dias + 1,
            ultima_actividad = NOW(),
            updated_at = NOW()
        WHERE user_id = p_usuario_id
        RETURNING racha_dias INTO dias_racha;
    ELSE
        -- Rompió la racha, reiniciar
        UPDATE perfiles SET 
            racha_dias = 1,
            ultima_actividad = NOW(),
            updated_at = NOW()
        WHERE user_id = p_usuario_id
        RETURNING racha_dias INTO dias_racha;
    END IF;
    
    RETURN dias_racha;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 6️⃣ TRIGGER PARA SINCRONIZACIÓN AUTOMÁTICA
-- ====================================

CREATE OR REPLACE FUNCTION trigger_sincronizar_membresia()
RETURNS TRIGGER AS $$
BEGIN
    -- Sincronizar membresía cuando cambie la suscripción
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.estado IS DISTINCT FROM NEW.estado) THEN
        PERFORM sincronizar_membresia_perfil(NEW.usuario_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger en tabla suscripciones_usuario
DROP TRIGGER IF EXISTS trigger_sincronizar_membresia_perfil ON suscripciones_usuario;
CREATE TRIGGER trigger_sincronizar_membresia_perfil
    AFTER INSERT OR UPDATE ON suscripciones_usuario
    FOR EACH ROW
    EXECUTE FUNCTION trigger_sincronizar_membresia();

-- ====================================
-- 7️⃣ VIEW PARA INFORMACIÓN COMPLETA DE USUARIO
-- ====================================

CREATE OR REPLACE VIEW vista_usuario_completo AS
SELECT 
    p.user_id,
    p.username,
    p.nombre_completo,
    p.email,
    p.avatar_url,
    p.suscripcion,
    
    -- Información de membresía
    m.nombre as membresia_nombre,
    m.descripcion as membresia_descripcion,
    m.color_hex as membresia_color,
    m.permisos as membresia_permisos,
    p.fecha_inicio_membresia,
    p.fecha_vencimiento_membresia,
    
    -- Estado de suscripción
    su.estado as suscripcion_estado,
    su.precio_pagado,
    su.periodo as periodo_pago,
    (p.fecha_vencimiento_membresia - CURRENT_DATE) as dias_restantes,
    
    -- Gamificación
    p.nivel_usuario,
    p.experiencia_total,
    p.puntos_experiencia,
    p.racha_dias,
    p.logros_obtenidos,
    p.insignias,
    
    -- Actividad
    p.primera_vez,
    p.onboarding_completado,
    p.ultima_actividad,
    
    -- Configuraciones
    p.configuracion_simulador,
    p.preferencias_contenido,
    p.preferencias_membresia,
    
    -- Timestamps
    p.created_at,
    p.updated_at
    
FROM perfiles p
LEFT JOIN membresias m ON p.membresia_activa_id = m.id
LEFT JOIN suscripciones_usuario su ON (
    su.usuario_id = p.user_id 
    AND su.estado = 'activa' 
    AND su.fecha_vencimiento >= CURRENT_DATE
);

-- ====================================
-- 8️⃣ SINCRONIZAR PERFILES EXISTENTES
-- ====================================

-- Actualizar todos los perfiles existentes
DO $$
DECLARE
    perfil_record RECORD;
    total_actualizados INTEGER := 0;
BEGIN
    FOR perfil_record IN 
        SELECT DISTINCT user_id FROM perfiles 
    LOOP
        PERFORM sincronizar_membresia_perfil(perfil_record.user_id);
        total_actualizados := total_actualizados + 1;
    END LOOP;
    
    RAISE NOTICE '📊 Perfiles sincronizados: %', total_actualizados;
END $$;

-- ====================================
-- 9️⃣ DATOS DE PRUEBA Y CONFIGURACIÓN INICIAL
-- ====================================

-- Actualizar configuraciones por defecto para usuarios existentes
UPDATE perfiles SET
    primera_vez = CASE 
        WHEN created_at > NOW() - INTERVAL '7 days' THEN true
        ELSE false
    END,
    onboarding_completado = CASE 
        WHEN created_at < NOW() - INTERVAL '7 days' THEN true
        ELSE false
    END,
    nivel_usuario = GREATEST(1, FLOOR(RANDOM() * 5) + 1),
    experiencia_total = FLOOR(RANDOM() * 5000),
    puntos_experiencia = FLOOR(RANDOM() * 1000),
    racha_dias = FLOOR(RANDOM() * 30)
WHERE configuracion_simulador = '{
    "volumen": 50,
    "velocidad_metronomo": 120,
    "tono_favorito": "DO",
    "modo_practica": "libre",
    "mostrar_notas": true,
    "grabacion_automatica": false
}'::jsonb;

-- ====================================
-- 🔟 VERIFICACIONES Y VALIDACIONES
-- ====================================

DO $$
DECLARE
    total_perfiles INTEGER;
    perfiles_con_membresia INTEGER;
    ejemplo_perfil RECORD;
BEGIN
    -- Contar perfiles
    SELECT COUNT(*) INTO total_perfiles FROM perfiles;
    
    SELECT COUNT(*) INTO perfiles_con_membresia 
    FROM perfiles WHERE membresia_activa_id IS NOT NULL;
    
    RAISE NOTICE '👥 Total de perfiles: %', total_perfiles;
    RAISE NOTICE '💎 Perfiles con membresía: %', perfiles_con_membresia;
    
    -- Mostrar ejemplo de perfil actualizado
    SELECT 
        username,
        suscripcion,
        nivel_usuario,
        experiencia_total,
        fecha_vencimiento_membresia
    INTO ejemplo_perfil
    FROM perfiles 
    WHERE membresia_activa_id IS NOT NULL
    LIMIT 1;
    
    IF ejemplo_perfil.username IS NOT NULL THEN
        RAISE NOTICE '🎯 Ejemplo perfil: % (%) - Nivel: % - Exp: % - Vence: %', 
            ejemplo_perfil.username,
            ejemplo_perfil.suscripcion,
            ejemplo_perfil.nivel_usuario,
            ejemplo_perfil.experiencia_total,
            ejemplo_perfil.fecha_vencimiento_membresia;
    END IF;
    
    RAISE NOTICE '✅ ¡Tabla perfiles actualizada exitosamente!';
END $$;

-- ====================================
-- 1️⃣1️⃣ COMENTARIOS Y DOCUMENTACIÓN
-- ====================================

COMMENT ON COLUMN perfiles.membresia_activa_id IS 'Referencia a la membresía activa del usuario';
COMMENT ON COLUMN perfiles.configuracion_simulador IS 'Configuraciones personalizadas del simulador de acordeón';
COMMENT ON COLUMN perfiles.preferencias_contenido IS 'Preferencias de tipos de contenido y notificaciones';
COMMENT ON COLUMN perfiles.logros_obtenidos IS 'Array de logros desbloqueados por el usuario';
COMMENT ON COLUMN perfiles.experiencia_total IS 'Puntos de experiencia acumulados de por vida';
COMMENT ON COLUMN perfiles.racha_dias IS 'Días consecutivos de actividad en la plataforma';

-- ====================================
-- ✅ SCRIPT COMPLETADO
-- ====================================

SELECT 
    '🎉 ¡FASE 1.3 COMPLETADA EXITOSAMENTE!' as mensaje,
    COUNT(*) as total_perfiles,
    COUNT(CASE WHEN membresia_activa_id IS NOT NULL THEN 1 END) as con_membresia,
    AVG(nivel_usuario) as nivel_promedio,
    SUM(experiencia_total) as experiencia_total_comunidad
FROM perfiles; 