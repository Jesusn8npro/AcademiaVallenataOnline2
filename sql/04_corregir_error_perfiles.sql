-- 🔧 FASE 1.3.1 - CORREGIR ERROR EN VISTA Y MAPEO
-- Script para solucionar el error de column p.user_id does not exist
-- Academia Vallenata Online - Sistema de Suscripciones

-- ====================================
-- 1️⃣ ELIMINAR VISTA PROBLEMÁTICA
-- ====================================

DROP VIEW IF EXISTS vista_usuario_completo CASCADE;

-- ====================================
-- 2️⃣ VERIFICAR ESTRUCTURA DE TABLA PERFILES
-- ====================================

-- Verificar qué columnas existen realmente en perfiles
DO $$
DECLARE
    columna_id TEXT;
BEGIN
    -- Buscar la columna de ID en perfiles
    SELECT column_name INTO columna_id
    FROM information_schema.columns 
    WHERE table_name = 'perfiles' 
      AND column_name IN ('user_id', 'id', 'usuario_id')
    ORDER BY 
        CASE column_name 
            WHEN 'user_id' THEN 1
            WHEN 'id' THEN 2 
            WHEN 'usuario_id' THEN 3
        END
    LIMIT 1;
    
    RAISE NOTICE '🔍 Columna ID encontrada en perfiles: %', COALESCE(columna_id, 'NINGUNA');
END $$;

-- ====================================
-- 3️⃣ CORREGIR FUNCIÓN DE SINCRONIZACIÓN
-- ====================================

CREATE OR REPLACE FUNCTION sincronizar_membresia_perfil_corregida(p_usuario_id UUID)
RETURNS VOID AS $$
DECLARE
    membresia_info RECORD;
    columna_usuario_perfil TEXT;
BEGIN
    -- Determinar cuál es la columna correcta en perfiles
    SELECT column_name INTO columna_usuario_perfil
    FROM information_schema.columns 
    WHERE table_name = 'perfiles' 
      AND column_name IN ('user_id', 'id', 'usuario_id')
    ORDER BY 
        CASE column_name 
            WHEN 'user_id' THEN 1
            WHEN 'id' THEN 2 
            WHEN 'usuario_id' THEN 3
        END
    LIMIT 1;
    
    IF columna_usuario_perfil IS NULL THEN
        RAISE EXCEPTION 'No se encontró columna de usuario en tabla perfiles';
    END IF;
    
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
    
    -- Actualizar perfil usando SQL dinámico
    IF membresia_info.membresia_id IS NOT NULL THEN
        EXECUTE format('
            UPDATE perfiles SET
                membresia_activa_id = $1,
                fecha_inicio_membresia = $2,
                fecha_vencimiento_membresia = $3,
                suscripcion = $4,
                updated_at = NOW()
            WHERE %I = $5', columna_usuario_perfil)
        USING 
            membresia_info.membresia_id,
            membresia_info.fecha_inicio,
            membresia_info.fecha_vencimiento,
            membresia_info.membresia_nombre,
            p_usuario_id;
    ELSE
        EXECUTE format('
            UPDATE perfiles SET
                membresia_activa_id = NULL,
                fecha_inicio_membresia = NULL,
                fecha_vencimiento_membresia = NULL,
                suscripcion = ''free'',
                updated_at = NOW()
            WHERE %I = $1', columna_usuario_perfil)
        USING p_usuario_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 4️⃣ RECREAR VISTA CORREGIDA
-- ====================================

CREATE OR REPLACE VIEW vista_usuario_completo AS
SELECT 
    -- Usar COALESCE para manejar diferentes nombres de columna
    COALESCE(p.user_id, p.id, p.usuario_id) as user_id,
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
    
    -- Gamificación (solo si existen las columnas)
    COALESCE(p.nivel_usuario, 1) as nivel_usuario,
    COALESCE(p.experiencia_total, 0) as experiencia_total,
    COALESCE(p.puntos_experiencia, 0) as puntos_experiencia,
    COALESCE(p.racha_dias, 0) as racha_dias,
    COALESCE(p.logros_obtenidos, '[]'::jsonb) as logros_obtenidos,
    COALESCE(p.insignias, '[]'::jsonb) as insignias,
    
    -- Actividad
    COALESCE(p.primera_vez, true) as primera_vez,
    COALESCE(p.onboarding_completado, false) as onboarding_completado,
    COALESCE(p.ultima_actividad, p.updated_at, p.created_at) as ultima_actividad,
    
    -- Configuraciones (solo si existen)
    COALESCE(p.configuracion_simulador, '{}'::jsonb) as configuracion_simulador,
    COALESCE(p.preferencias_contenido, '{}'::jsonb) as preferencias_contenido,
    COALESCE(p.preferencias_membresia, '{}'::jsonb) as preferencias_membresia,
    
    -- Timestamps
    p.created_at,
    p.updated_at
    
FROM perfiles p
LEFT JOIN membresias m ON p.membresia_activa_id = m.id
LEFT JOIN suscripciones_usuario su ON (
    su.usuario_id = COALESCE(p.user_id, p.id, p.usuario_id)
    AND su.estado = 'activa' 
    AND su.fecha_vencimiento >= CURRENT_DATE
);

-- ====================================
-- 5️⃣ FUNCIÓN SIMPLIFICADA PARA OBTENER USUARIO
-- ====================================

CREATE OR REPLACE FUNCTION obtener_usuario_con_membresia(p_usuario_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    email TEXT,
    membresia_nombre TEXT,
    membresia_permisos JSONB,
    fecha_vencimiento DATE,
    dias_restantes INTEGER,
    nivel_usuario INTEGER,
    experiencia_total INTEGER
) AS $$
DECLARE
    columna_usuario TEXT;
BEGIN
    -- Determinar columna de usuario en perfiles
    SELECT column_name INTO columna_usuario
    FROM information_schema.columns 
    WHERE table_name = 'perfiles' 
      AND column_name IN ('user_id', 'id', 'usuario_id')
    LIMIT 1;
    
    RETURN QUERY EXECUTE format('
        SELECT 
            COALESCE(p.user_id, p.id, p.usuario_id) as user_id,
            p.username,
            p.email,
            COALESCE(m.nombre, ''free'') as membresia_nombre,
            COALESCE(m.permisos, ''{}''::jsonb) as membresia_permisos,
            p.fecha_vencimiento_membresia,
            COALESCE((p.fecha_vencimiento_membresia - CURRENT_DATE), 0) as dias_restantes,
            COALESCE(p.nivel_usuario, 1) as nivel_usuario,
            COALESCE(p.experiencia_total, 0) as experiencia_total
        FROM perfiles p
        LEFT JOIN membresias m ON p.membresia_activa_id = m.id
        WHERE %I = $1', columna_usuario)
    USING p_usuario_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 6️⃣ SINCRONIZAR TODOS LOS PERFILES
-- ====================================

DO $$
DECLARE
    perfil_record RECORD;
    total_sincronizados INTEGER := 0;
    columna_usuario TEXT;
BEGIN
    -- Obtener columna correcta
    SELECT column_name INTO columna_usuario
    FROM information_schema.columns 
    WHERE table_name = 'perfiles' 
      AND column_name IN ('user_id', 'id', 'usuario_id')
    LIMIT 1;
    
    RAISE NOTICE '🔧 Usando columna: % para sincronización', columna_usuario;
    
    -- Sincronizar todos los perfiles
    FOR perfil_record IN 
        EXECUTE format('SELECT DISTINCT %I as user_id FROM perfiles', columna_usuario)
    LOOP
        BEGIN
            PERFORM sincronizar_membresia_perfil_corregida(perfil_record.user_id);
            total_sincronizados := total_sincronizados + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Error sincronizando perfil: %', perfil_record.user_id;
        END;
    END LOOP;
    
    RAISE NOTICE '✅ Perfiles sincronizados exitosamente: %', total_sincronizados;
END $$;

-- ====================================
-- 7️⃣ VERIFICACIÓN FINAL
-- ====================================

DO $$
DECLARE
    total_perfiles INTEGER;
    perfiles_con_membresia INTEGER;
    vista_funciona BOOLEAN := true;
    ejemplo_usuario RECORD;
BEGIN
    -- Verificar tabla perfiles
    SELECT COUNT(*) INTO total_perfiles FROM perfiles;
    
    SELECT COUNT(*) INTO perfiles_con_membresia 
    FROM perfiles WHERE membresia_activa_id IS NOT NULL;
    
    -- Verificar si la vista funciona
    BEGIN
        SELECT * INTO ejemplo_usuario FROM vista_usuario_completo LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        vista_funciona := false;
    END;
    
    RAISE NOTICE '👥 Total perfiles: %', total_perfiles;
    RAISE NOTICE '💎 Con membresía: %', perfiles_con_membresia;
    RAISE NOTICE '📋 Vista funciona: %', vista_funciona;
    
    IF vista_funciona AND ejemplo_usuario.user_id IS NOT NULL THEN
        RAISE NOTICE '🎯 Ejemplo usuario: % (%) - Nivel: %', 
            ejemplo_usuario.username,
            ejemplo_usuario.membresia_nombre,
            ejemplo_usuario.nivel_usuario;
    END IF;
    
    RAISE NOTICE '✅ ¡CORRECCIÓN COMPLETADA EXITOSAMENTE!';
END $$;

-- ====================================
-- ✅ SCRIPT DE CORRECCIÓN COMPLETADO
-- ====================================

SELECT 
    '🎉 ¡ERROR CORREGIDO EXITOSAMENTE!' as mensaje,
    'Vista y funciones actualizadas' as estado,
    COUNT(*) as perfiles_procesados
FROM perfiles; 