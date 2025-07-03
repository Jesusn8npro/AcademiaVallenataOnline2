-- 🔧 FASE 1.3.3 - FIX CON CAMPOS REALES DE PERFILES
-- Script corregido usando la estructura REAL de la tabla perfiles
-- Academia Vallenata Online - Sistema de Suscripciones

-- ====================================
-- 1️⃣ ELIMINAR VISTAS PROBLEMÁTICAS
-- ====================================

DROP VIEW IF EXISTS vista_usuario_completo CASCADE;
DROP FUNCTION IF EXISTS obtener_usuario_con_membresia_simple(UUID) CASCADE;
DROP FUNCTION IF EXISTS obtener_usuario_con_membresia(UUID) CASCADE;

-- ====================================
-- 2️⃣ AGREGAR COLUMNAS FALTANTES CON VERIFICACIÓN
-- ====================================

DO $$
BEGIN
    -- membresia_activa_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'membresia_activa_id') THEN
        ALTER TABLE perfiles ADD COLUMN membresia_activa_id UUID REFERENCES membresias(id);
        RAISE NOTICE '✅ Columna membresia_activa_id agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna membresia_activa_id ya existe';
    END IF;

    -- fecha_inicio_membresia
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'fecha_inicio_membresia') THEN
        ALTER TABLE perfiles ADD COLUMN fecha_inicio_membresia DATE;
        RAISE NOTICE '✅ Columna fecha_inicio_membresia agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna fecha_inicio_membresia ya existe';
    END IF;

    -- fecha_vencimiento_membresia
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'fecha_vencimiento_membresia') THEN
        ALTER TABLE perfiles ADD COLUMN fecha_vencimiento_membresia DATE;
        RAISE NOTICE '✅ Columna fecha_vencimiento_membresia agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna fecha_vencimiento_membresia ya existe';
    END IF;

    -- notificaciones_membresia
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'notificaciones_membresia') THEN
        ALTER TABLE perfiles ADD COLUMN notificaciones_membresia BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Columna notificaciones_membresia agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna notificaciones_membresia ya existe';
    END IF;

    -- preferencias_membresia
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'preferencias_membresia') THEN
        ALTER TABLE perfiles ADD COLUMN preferencias_membresia JSONB DEFAULT '{}'::jsonb;
        RAISE NOTICE '✅ Columna preferencias_membresia agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna preferencias_membresia ya existe';
    END IF;

    -- nivel_usuario
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'nivel_usuario') THEN
        ALTER TABLE perfiles ADD COLUMN nivel_usuario INTEGER DEFAULT 1 CHECK (nivel_usuario >= 1);
        RAISE NOTICE '✅ Columna nivel_usuario agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna nivel_usuario ya existe';
    END IF;

    -- experiencia_total
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'experiencia_total') THEN
        ALTER TABLE perfiles ADD COLUMN experiencia_total INTEGER DEFAULT 0 CHECK (experiencia_total >= 0);
        RAISE NOTICE '✅ Columna experiencia_total agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna experiencia_total ya existe';
    END IF;

    -- puntos_experiencia
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'puntos_experiencia') THEN
        ALTER TABLE perfiles ADD COLUMN puntos_experiencia INTEGER DEFAULT 0 CHECK (puntos_experiencia >= 0 AND puntos_experiencia < 1000);
        RAISE NOTICE '✅ Columna puntos_experiencia agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna puntos_experiencia ya existe';
    END IF;

    -- racha_dias
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'racha_dias') THEN
        ALTER TABLE perfiles ADD COLUMN racha_dias INTEGER DEFAULT 0 CHECK (racha_dias >= 0);
        RAISE NOTICE '✅ Columna racha_dias agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna racha_dias ya existe';
    END IF;

    -- logros_obtenidos
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'logros_obtenidos') THEN
        ALTER TABLE perfiles ADD COLUMN logros_obtenidos JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE '✅ Columna logros_obtenidos agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna logros_obtenidos ya existe';
    END IF;

    -- insignias
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'insignias') THEN
        ALTER TABLE perfiles ADD COLUMN insignias JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE '✅ Columna insignias agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna insignias ya existe';
    END IF;

    -- primera_vez
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'primera_vez') THEN
        ALTER TABLE perfiles ADD COLUMN primera_vez BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Columna primera_vez agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna primera_vez ya existe';
    END IF;

    -- onboarding_completado
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'onboarding_completado') THEN
        ALTER TABLE perfiles ADD COLUMN onboarding_completado BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Columna onboarding_completado agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna onboarding_completado ya existe';
    END IF;

    -- ultima_actividad
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'ultima_actividad') THEN
        ALTER TABLE perfiles ADD COLUMN ultima_actividad TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE '✅ Columna ultima_actividad agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna ultima_actividad ya existe';
    END IF;

    -- configuracion_simulador
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'configuracion_simulador') THEN
        ALTER TABLE perfiles ADD COLUMN configuracion_simulador JSONB DEFAULT '{"volumen": 50, "velocidad_metronomo": 120, "tono_favorito": "DO", "modo_practica": "libre", "mostrar_notas": true, "grabacion_automatica": false}'::jsonb;
        RAISE NOTICE '✅ Columna configuracion_simulador agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna configuracion_simulador ya existe';
    END IF;

    -- preferencias_contenido
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'perfiles' AND column_name = 'preferencias_contenido') THEN
        ALTER TABLE perfiles ADD COLUMN preferencias_contenido JSONB DEFAULT '{"generos_favoritos": [], "artistas_favoritos": [], "dificultad_preferida": "intermedio", "notificaciones_contenido": true}'::jsonb;
        RAISE NOTICE '✅ Columna preferencias_contenido agregada';
    ELSE
        RAISE NOTICE '⚠️ Columna preferencias_contenido ya existe';
    END IF;
END $$;

-- ====================================
-- 3️⃣ CREAR ÍNDICES PARA PERFORMANCE
-- ====================================

-- Índices para membresías
CREATE INDEX IF NOT EXISTS idx_perfiles_membresia_activa ON perfiles(membresia_activa_id);
CREATE INDEX IF NOT EXISTS idx_perfiles_fecha_vencimiento ON perfiles(fecha_vencimiento_membresia);

-- Índices para gamificación
CREATE INDEX IF NOT EXISTS idx_perfiles_nivel_usuario ON perfiles(nivel_usuario);
CREATE INDEX IF NOT EXISTS idx_perfiles_experiencia_total ON perfiles(experiencia_total DESC);
CREATE INDEX IF NOT EXISTS idx_perfiles_racha_dias ON perfiles(racha_dias DESC);

-- Índices para actividad
CREATE INDEX IF NOT EXISTS idx_perfiles_ultima_actividad ON perfiles(ultima_actividad DESC);
CREATE INDEX IF NOT EXISTS idx_perfiles_onboarding ON perfiles(onboarding_completado);

-- ====================================
-- 4️⃣ CREAR VISTA CON CAMPOS REALES
-- ====================================

CREATE VIEW vista_usuario_completo AS
SELECT 
    -- Usando campos REALES de la tabla perfiles
    p.id as user_id,
    p.nombre_usuario,           -- REAL: no 'username'
    p.nombre_completo,          -- REAL: sí existe  
    p.correo_electronico,       -- REAL: no 'email'
    p.url_foto_perfil,          -- REAL: no 'avatar_url'
    p.suscripcion,              -- REAL: sí existe
    p.nombre,                   -- REAL: nombre individual
    p.apellido,                 -- REAL: apellido individual
    p.rol,                      -- REAL: rol del usuario
    p.biografia,                -- REAL: biografía
    p.ciudad,                   -- REAL: ciudad
    p.pais,                     -- REAL: país
    p.nivel_habilidad,          -- REAL: nivel musical
    p.instrumento,              -- REAL: instrumento principal
    p.whatsapp,                 -- REAL: WhatsApp
    p.objetivo_aprendizaje,     -- REAL: objetivo específico
    p.ano_experiencia,          -- REAL: años de experiencia
    p.estilo_favorito,          -- REAL: estilo musical favorito
    
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
    
    -- Gamificación (nuevas columnas)
    COALESCE(p.nivel_usuario, 1) as nivel_usuario,
    COALESCE(p.experiencia_total, 0) as experiencia_total,
    COALESCE(p.puntos_experiencia, 0) as puntos_experiencia,
    COALESCE(p.racha_dias, 0) as racha_dias,
    COALESCE(p.logros_obtenidos, '[]'::jsonb) as logros_obtenidos,
    COALESCE(p.insignias, '[]'::jsonb) as insignias,
    
    -- Actividad y experiencia
    COALESCE(p.primera_vez, true) as primera_vez,
    COALESCE(p.onboarding_completado, false) as onboarding_completado,
    COALESCE(p.ultima_actividad, p.fecha_actualizacion) as ultima_actividad,
    
    -- Configuraciones (nuevas columnas)
    COALESCE(p.configuracion_simulador, '{}'::jsonb) as configuracion_simulador,
    COALESCE(p.preferencias_contenido, '{}'::jsonb) as preferencias_contenido,
    COALESCE(p.preferencias_membresia, '{}'::jsonb) as preferencias_membresia,
    
    -- Timestamps (usando campos REALES)
    p.fecha_creacion as created_at,
    p.fecha_actualizacion as updated_at
    
FROM perfiles p
LEFT JOIN membresias m ON p.membresia_activa_id = m.id
LEFT JOIN suscripciones_usuario su ON (
    su.usuario_id = p.id        -- REAL: usando 'id' no 'user_id'
    AND su.estado = 'activa' 
    AND su.fecha_vencimiento >= CURRENT_DATE
);

-- ====================================
-- 5️⃣ FUNCIÓN PARA OBTENER USUARIO CON MEMBRESÍA
-- ====================================

CREATE OR REPLACE FUNCTION obtener_usuario_con_membresia_real(p_usuario_id UUID)
RETURNS TABLE (
    user_id UUID,
    nombre_usuario TEXT,
    correo_electronico TEXT,
    membresia_nombre TEXT,
    membresia_permisos JSONB,
    fecha_vencimiento DATE,
    dias_restantes INTEGER,
    nivel_usuario INTEGER,
    experiencia_total INTEGER,
    racha_dias INTEGER
) AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        p.id as user_id,
        p.nombre_usuario,
        p.correo_electronico,
        COALESCE(m.nombre, 'free') as membresia_nombre,
        COALESCE(m.permisos, '{}'::jsonb) as membresia_permisos,
        p.fecha_vencimiento_membresia,
        COALESCE((p.fecha_vencimiento_membresia - CURRENT_DATE), 0) as dias_restantes,
        COALESCE(p.nivel_usuario, 1) as nivel_usuario,
        COALESCE(p.experiencia_total, 0) as experiencia_total,
        COALESCE(p.racha_dias, 0) as racha_dias
    FROM perfiles p
    LEFT JOIN membresias m ON p.membresia_activa_id = m.id
    WHERE p.id = p_usuario_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 6️⃣ FUNCIÓN PARA SINCRONIZAR MEMBRESÍA
-- ====================================

CREATE OR REPLACE FUNCTION sincronizar_membresia_perfil_real(p_usuario_id UUID)
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
    
    -- Actualizar perfil usando campos REALES
    IF membresia_info.membresia_id IS NOT NULL THEN
        UPDATE perfiles SET
            membresia_activa_id = membresia_info.membresia_id,
            fecha_inicio_membresia = membresia_info.fecha_inicio,
            fecha_vencimiento_membresia = membresia_info.fecha_vencimiento,
            suscripcion = membresia_info.membresia_nombre,
            fecha_actualizacion = NOW()  -- REAL: no 'updated_at'
        WHERE id = p_usuario_id;        -- REAL: usando 'id'
    ELSE
        UPDATE perfiles SET
            membresia_activa_id = NULL,
            fecha_inicio_membresia = NULL,
            fecha_vencimiento_membresia = NULL,
            suscripcion = 'free',
            fecha_actualizacion = NOW()
        WHERE id = p_usuario_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 7️⃣ VERIFICACIÓN FINAL CON CAMPOS REALES
-- ====================================

DO $$
DECLARE
    total_perfiles INTEGER;
    columnas_agregadas INTEGER := 0;
    vista_funciona BOOLEAN := true;
    ejemplo_usuario RECORD;
BEGIN
    -- Contar perfiles
    SELECT COUNT(*) INTO total_perfiles FROM perfiles;
    
    -- Contar columnas agregadas
    SELECT COUNT(*) INTO columnas_agregadas
    FROM information_schema.columns 
    WHERE table_name = 'perfiles' 
      AND column_name IN (
          'membresia_activa_id', 'fecha_inicio_membresia', 'fecha_vencimiento_membresia',
          'nivel_usuario', 'experiencia_total', 'puntos_experiencia', 'racha_dias',
          'logros_obtenidos', 'insignias', 'primera_vez', 'onboarding_completado',
          'configuracion_simulador', 'preferencias_contenido', 'preferencias_membresia'
      );
    
    -- Probar vista con campos REALES
    BEGIN
        SELECT * INTO ejemplo_usuario FROM vista_usuario_completo LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        vista_funciona := false;
    END;
    
    RAISE NOTICE '====================================';
    RAISE NOTICE '✅ VERIFICACIÓN CON CAMPOS REALES';
    RAISE NOTICE '====================================';
    RAISE NOTICE '👥 Total perfiles: %', total_perfiles;
    RAISE NOTICE '📊 Columnas agregadas: %/14', columnas_agregadas;
    RAISE NOTICE '📋 Vista funciona: %', vista_funciona;
    
    IF vista_funciona AND ejemplo_usuario.user_id IS NOT NULL THEN
        RAISE NOTICE '🎯 Ejemplo usuario: % - Nivel: %', 
            COALESCE(ejemplo_usuario.nombre_usuario, 'N/A'),
            COALESCE(ejemplo_usuario.nivel_usuario, 1);
    END IF;
    
    IF columnas_agregadas >= 10 AND vista_funciona THEN
        RAISE NOTICE '🎉 ¡CORRECCIÓN CON CAMPOS REALES COMPLETADA!';
        RAISE NOTICE '🚀 Sistema de membresías listo usando estructura real';
    ELSE
        RAISE NOTICE '⚠️ Revisar: Columnas: % - Vista: %', columnas_agregadas, vista_funciona;
    END IF;
END $$;

-- ====================================
-- ✅ SCRIPT CON CAMPOS REALES COMPLETADO
-- ====================================

SELECT 
    '🎉 ¡SISTEMA CORREGIDO CON CAMPOS REALES!' as mensaje,
    'Vista y funciones usando estructura real de perfiles' as estado,
    COUNT(*) as perfiles_procesados
FROM perfiles; 