-- 🎯 FASE 1.1 - CREAR TABLA DE MEMBRESÍAS
-- Script para crear la tabla base del sistema de membresías
-- Academia Vallenata Online - Sistema de Suscripciones

-- ====================================
-- 1️⃣ CREAR TABLA MEMBRESÍAS
-- ====================================

CREATE TABLE IF NOT EXISTS membresias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 📋 Información básica
    nombre TEXT NOT NULL UNIQUE,
    descripcion TEXT NOT NULL,
    precio_mensual DECIMAL(10,2) NOT NULL CHECK (precio_mensual >= 0),
    precio_anual DECIMAL(10,2) CHECK (precio_anual >= 0),
    
    -- 🎨 Configuración visual
    color_hex TEXT DEFAULT '#6366f1',
    icono TEXT DEFAULT '🎵',
    orden INTEGER NOT NULL,
    
    -- 🔧 Configuración funcional
    activa BOOLEAN DEFAULT true,
    destacada BOOLEAN DEFAULT false, -- Para marcar el plan "más popular"
    
    -- 📊 Beneficios y permisos (JSON)
    beneficios JSONB NOT NULL DEFAULT '[]'::jsonb,
    permisos JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- 🎯 Marketing
    tagline TEXT, -- "Ideal para comenzar", "La más popular", etc.
    descuento_anual INTEGER DEFAULT 20, -- Porcentaje de descuento anual
    
    -- ⏰ Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ====================================
-- 2️⃣ CREAR ÍNDICES PARA OPTIMIZACIÓN
-- ====================================

CREATE INDEX IF NOT EXISTS idx_membresias_activa ON membresias(activa);
CREATE INDEX IF NOT EXISTS idx_membresias_orden ON membresias(orden);
CREATE INDEX IF NOT EXISTS idx_membresias_precio ON membresias(precio_mensual);

-- ====================================
-- 3️⃣ CREAR TRIGGER DE UPDATED_AT
-- ====================================

CREATE OR REPLACE FUNCTION actualizar_updated_at_membresias()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_membresias_updated_at ON membresias;
CREATE TRIGGER trigger_membresias_updated_at
    BEFORE UPDATE ON membresias
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at_membresias();

-- ====================================
-- 4️⃣ INSERTAR MEMBRESÍAS BASE
-- ====================================

-- 🥉 MEMBRESÍA BÁSICA
INSERT INTO membresias (
    nombre, 
    descripcion, 
    precio_mensual, 
    precio_anual, 
    color_hex, 
    icono, 
    orden, 
    destacada,
    tagline,
    beneficios,
    permisos
) VALUES (
    'Básica',
    'Perfecto para empezar a aprender acordeón vallenato desde cero',
    15000.00,  -- $15.000 COP
    144000.00, -- $144.000 COP (20% descuento anual)
    '#10b981',
    '🌱',
    1,
    false,
    'Ideal para comenzar',
    '[
        "Acceso completo al simulador básico de acordeón",
        "Metrónomo integrado con tempos básicos", 
        "Cambio de tonos (5 tonos disponibles)",
        "Grabación de práctica (máximo 10 minutos por día)",
        "Acceso completo a la comunidad",
        "Participación en ranking y gamificación",
        "3 tutoriales gratuitos rotatorios por mes"
    ]'::jsonb,
    '{
        "simulador": {
            "tipo": "basico",
            "tonos_disponibles": 5,
            "grabacion_max_minutos_dia": 10,
            "metronomo": "basico",
            "efectos": false,
            "videojuego": false
        },
        "contenido": {
            "tutoriales_gratis_mes": 3,
            "tutoriales_premium": false,
            "cursos_acceso": false,
            "eventos_acceso": false
        },
        "comunidad": {
            "acceso_completo": true,
            "publicar": true,
            "comentar": true,
            "likes": true
        }
    }'::jsonb
),

-- 🥈 MEMBRESÍA INTERMEDIA 
(
    'Intermedia',
    'La opción más popular - Acceso completo a tutoriales y simulador avanzado',
    35000.00,  -- $35.000 COP
    336000.00, -- $336.000 COP (20% descuento anual)
    '#3b82f6',
    '⭐',
    2,
    true, -- DESTACADA - La más popular
    'La más popular',
    '[
        "Todo lo incluido en el plan Básico",
        "Simulador de acordeón completo y avanzado",
        "Todos los tonos disponibles (12 tonos)",
        "Grabación ilimitada con análisis de ritmo",
        "Modo videojuego interactivo",
        "Efectos de sonido realistas",
        "Acceso completo a TODOS los tutoriales",
        "Tutoriales interactivos del simulador",
        "Acceso a eventos virtuales (grabaciones)",
        "Descarga de partituras básicas"
    ]'::jsonb,
    '{
        "simulador": {
            "tipo": "completo",
            "tonos_disponibles": 12,
            "grabacion_ilimitada": true,
            "metronomo": "avanzado",
            "efectos": true,
            "videojuego": true,
            "analisis_ritmo": true
        },
        "contenido": {
            "tutoriales_acceso": "completo",
            "tutoriales_interactivos": true,
            "cursos_acceso": false,
            "eventos_grabaciones": true,
            "partituras_basicas": true
        },
        "comunidad": {
            "acceso_completo": true,
            "publicar": true,
            "comentar": true,
            "likes": true,
            "badge_especial": true
        }
    }'::jsonb
),

-- 🥇 MEMBRESÍA AVANZADA
(
    'Avanzada',
    'Para estudiantes serios - Acceso a cursos completos y eventos en vivo',
    65000.00,  -- $65.000 COP
    624000.00, -- $624.000 COP (20% descuento anual)
    '#8b5cf6',
    '👑',
    3,
    false,
    'Para estudiantes serios',
    '[
        "Todo lo incluido en el plan Intermedia",
        "Acceso completo a TODOS los cursos",
        "Clases magistrales exclusivas",
        "Eventos en vivo (participación activa)",
        "Feedback personalizado en grabaciones",
        "Certificados oficiales de la academia",
        "Acceso prioritario a contenido nuevo",
        "Descarga de partituras avanzadas",
        "Soporte técnico prioritario"
    ]'::jsonb,
    '{
        "simulador": {
            "tipo": "completo",
            "tonos_disponibles": 12,
            "grabacion_ilimitada": true,
            "metronomo": "profesional",
            "efectos": true,
            "videojuego": true,
            "analisis_avanzado": true
        },
        "contenido": {
            "tutoriales_acceso": "completo",
            "cursos_acceso": "completo",
            "eventos_en_vivo": true,
            "clases_magistrales": true,
            "certificados": true,
            "partituras_avanzadas": true,
            "acceso_prioritario": true
        },
        "comunidad": {
            "acceso_completo": true,
            "publicar": true,
            "comentar": true,
            "likes": true,
            "badge_avanzado": true
        },
        "soporte": {
            "prioridad": "alta",
            "feedback_personalizado": true
        }
    }'::jsonb
),

-- 💎 MEMBRESÍA PREMIUM
(
    'Premium',
    'La experiencia élite - Clases personalizadas y acceso VIP total',
    120000.00, -- $120.000 COP
    1152000.00, -- $1.152.000 COP (20% descuento anual)
    '#f59e0b',
    '💎',
    4,
    false,
    'Experiencia élite',
    '[
        "Todo lo incluido en el plan Avanzada",
        "Clases individuales 1:1 con instructores (2 sesiones por mes)",
        "Clases en vivo grupales semanales",
        "Acceso VIP a eventos presenciales",
        "Contenido exclusivo antes que otros miembros",
        "Soporte técnico inmediato 24/7",
        "Asesoría personalizada de carrera musical",
        "Descuentos en instrumentos y productos",
        "Red de contactos exclusiva",
        "Invitaciones a eventos especiales"
    ]'::jsonb,
    '{
        "simulador": {
            "tipo": "elite",
            "tonos_disponibles": 12,
            "grabacion_ilimitada": true,
            "metronomo": "profesional",
            "efectos": true,
            "videojuego": true,
            "analisis_avanzado": true,
            "funciones_exclusivas": true
        },
        "contenido": {
            "tutoriales_acceso": "completo",
            "cursos_acceso": "completo",
            "eventos_en_vivo": true,
            "clases_1on1": 2,
            "clases_grupales": true,
            "contenido_exclusivo": true,
            "acceso_vip": true
        },
        "comunidad": {
            "acceso_completo": true,
            "publicar": true,
            "comentar": true,
            "likes": true,
            "badge_premium": true,
            "red_exclusiva": true
        },
        "soporte": {
            "prioridad": "maxima",
            "disponibilidad": "24_7",
            "asesoria_personalizada": true
        },
        "beneficios_extras": {
            "descuentos_instrumentos": true,
            "eventos_presenciales": true,
            "invitaciones_especiales": true
        }
    }'::jsonb
);

-- ====================================
-- 5️⃣ VERIFICACIONES Y VALIDACIONES
-- ====================================

-- Verificar que se insertaron correctamente
DO $$
DECLARE
    total_membresias INTEGER;
    membresia_record RECORD;
BEGIN
    -- Contar membresías insertadas
    SELECT COUNT(*) INTO total_membresias FROM membresias;
    
    RAISE NOTICE '✅ Total de membresías creadas: %', total_membresias;
    
    -- Mostrar cada membresía creada
    FOR membresia_record IN 
        SELECT nombre, precio_mensual, precio_anual, destacada, orden 
        FROM membresias 
        ORDER BY orden
    LOOP
        RAISE NOTICE '📋 % - $% mensual, $% anual (Destacada: %)', 
            membresia_record.nombre, 
            membresia_record.precio_mensual, 
            membresia_record.precio_anual,
            membresia_record.destacada;
    END LOOP;
    
    -- Verificar que hay una membresía destacada
    IF EXISTS (SELECT 1 FROM membresias WHERE destacada = true) THEN
        RAISE NOTICE '⭐ Membresía destacada configurada correctamente';
    ELSE
        RAISE WARNING '⚠️  No hay membresía marcada como destacada';
    END IF;
    
    RAISE NOTICE '🎯 ¡Tabla de membresías creada exitosamente!';
END $$;

-- ====================================
-- 6️⃣ COMENTARIOS FINALES
-- ====================================

COMMENT ON TABLE membresias IS 'Tabla que define los diferentes planes de membresía disponibles en la academia';
COMMENT ON COLUMN membresias.beneficios IS 'Array JSON con la lista de beneficios en texto plano para mostrar al usuario';
COMMENT ON COLUMN membresias.permisos IS 'Objeto JSON con la configuración técnica de permisos y límites por membresía';
COMMENT ON COLUMN membresias.destacada IS 'Indica si esta membresía debe mostrarse como "más popular" o destacada';
COMMENT ON COLUMN membresias.descuento_anual IS 'Porcentaje de descuento aplicado al plan anual vs 12 meses del mensual';

-- ====================================
-- ✅ SCRIPT COMPLETADO
-- ====================================

SELECT 
    '🎉 ¡FASE 1.1 COMPLETADA EXITOSAMENTE!' as mensaje,
    COUNT(*) as membresias_creadas,
    MIN(precio_mensual) as precio_minimo,
    MAX(precio_mensual) as precio_maximo
FROM membresias; 