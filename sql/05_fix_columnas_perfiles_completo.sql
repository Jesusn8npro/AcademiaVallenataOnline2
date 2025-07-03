-- 🔧 FASE 1.3.2 - FIX COMPLETO COLUMNAS PERFILES
-- Script para agregar columnas faltantes ANTES de crear vistas
-- Academia Vallenata Online - Sistema de Suscripciones

-- ====================================
-- 1️⃣ AGREGAR COLUMNAS FALTANTES A PERFILES
-- ====================================

-- Verificar y agregar columnas relacionadas con membresías
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
END $$;

-- ====================================
-- 2️⃣ AGREGAR COLUMNAS DE GAMIFICACIÓN
-- ====================================

DO $$
BEGIN
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
END $$;

-- ====================================
-- 3️⃣ AGREGAR COLUMNAS DE EXPERIENCIA
-- ====================================

DO $$
BEGIN
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
-- 4️⃣ CREAR ÍNDICES PARA PERFORMANCE
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
-- 5️⃣ AHORA SÍ CREAR VISTA CORREGIDA
-- ====================================

-- Eliminar vista problemática
DROP VIEW IF EXISTS vista_usuario_completo CASCADE;

-- Detectar columna de usuario dinámicamente y crear vista
DO $$
DECLARE
    columna_usuario TEXT;
    sql_vista TEXT;
BEGIN
    -- Determinar columna de usuario en perfiles
    SELECT column_name INTO columna_usuario
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
    
    IF columna_usuario IS NULL THEN
        RAISE EXCEPTION 'No se encontró columna de usuario en tabla perfiles';
    END IF;
    
    RAISE NOTICE '🔧 Creando vista con columna: %', columna_usuario;
    
    -- Crear vista dinámicamente
    sql_vista := format('
        CREATE VIEW vista_usuario_completo AS
        SELECT 
            p.%I as user_id,
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
            su.usuario_id = p.%I
            AND su.estado = ''activa'' 
            AND su.fecha_vencimiento >= CURRENT_DATE
        )', columna_usuario, columna_usuario);
    
    EXECUTE sql_vista;
    RAISE NOTICE '✅ Vista vista_usuario_completo creada exitosamente';
END $$;

-- ====================================
-- 6️⃣ CREAR FUNCIÓN SIMPLIFICADA
-- ====================================

CREATE OR REPLACE FUNCTION obtener_usuario_con_membresia_simple(p_usuario_id UUID)
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
            p.%I as user_id,
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
        WHERE p.%I = $1', columna_usuario, columna_usuario)
    USING p_usuario_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 7️⃣ VERIFICACIÓN FINAL COMPLETA
-- ====================================

DO $$
DECLARE
    total_perfiles INTEGER;
    columnas_agregadas INTEGER := 0;
    vista_funciona BOOLEAN := true;
    ejemplo_usuario RECORD;
    columna_usuario TEXT;
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
    
    -- Determinar columna de usuario
    SELECT column_name INTO columna_usuario
    FROM information_schema.columns 
    WHERE table_name = 'perfiles' 
      AND column_name IN ('user_id', 'id', 'usuario_id')
    LIMIT 1;
    
    -- Probar vista
    BEGIN
        SELECT * INTO ejemplo_usuario FROM vista_usuario_completo LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        vista_funciona := false;
    END;
    
    RAISE NOTICE '====================================';
    RAISE NOTICE '✅ VERIFICACIÓN FINAL COMPLETADA';
    RAISE NOTICE '====================================';
    RAISE NOTICE '👥 Total perfiles: %', total_perfiles;
    RAISE NOTICE '📊 Columnas agregadas: %/14', columnas_agregadas;
    RAISE NOTICE '🔧 Columna usuario detectada: %', COALESCE(columna_usuario, 'NO ENCONTRADA');
    RAISE NOTICE '📋 Vista funciona: %', vista_funciona;
    
    IF vista_funciona AND ejemplo_usuario.user_id IS NOT NULL THEN
        RAISE NOTICE '🎯 Ejemplo usuario: % - Nivel: %', 
            COALESCE(ejemplo_usuario.username, 'N/A'),
            COALESCE(ejemplo_usuario.nivel_usuario, 1);
    END IF;
    
    IF columnas_agregadas >= 10 AND vista_funciona THEN
        RAISE NOTICE '🎉 ¡CORRECCIÓN COMPLETADA EXITOSAMENTE!';
        RAISE NOTICE '🚀 Sistema de membresías listo para usar';
    ELSE
        RAISE NOTICE '⚠️ Algunas columnas pueden haber fallado';
    END IF;
END $$;

-- ====================================
-- ✅ SCRIPT COMPLETO FINALIZADO
-- ====================================

SELECT 
    '🎉 ¡SISTEMA DE MEMBRESÍAS PREPARADO!' as mensaje,
    'Columnas agregadas y vista corregida' as estado,
    COUNT(*) as perfiles_listos
FROM perfiles; 