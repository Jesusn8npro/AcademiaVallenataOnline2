-- 🎯 FASE 1.2 - CREAR TABLA SUSCRIPCIONES DE USUARIO
-- Script para crear la tabla que maneja las suscripciones activas de cada usuario
-- Academia Vallenata Online - Sistema de Suscripciones

-- ====================================
-- 1️⃣ CREAR TABLA SUSCRIPCIONES_USUARIO
-- ====================================

CREATE TABLE IF NOT EXISTS suscripciones_usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 👤 Referencias principales
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    membresia_id UUID NOT NULL REFERENCES membresias(id) ON DELETE RESTRICT,
    
    -- 📊 Estado de la suscripción
    estado TEXT NOT NULL DEFAULT 'activa' 
        CHECK (estado IN ('activa', 'pausada', 'cancelada', 'vencida', 'pendiente_pago')),
    
    -- 📅 Gestión de fechas
    fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_vencimiento DATE NOT NULL,
    fecha_cancelacion TIMESTAMP WITH TIME ZONE,
    fecha_pausada TIMESTAMP WITH TIME ZONE,
    
    -- 💰 Información de pago
    precio_pagado DECIMAL(10,2) NOT NULL CHECK (precio_pagado >= 0),
    periodo TEXT NOT NULL DEFAULT 'mensual' 
        CHECK (periodo IN ('mensual', 'anual')),
    
    -- 🔄 Configuración de renovación
    auto_renovar BOOLEAN DEFAULT true,
    intentos_renovacion INTEGER DEFAULT 0,
    max_intentos_renovacion INTEGER DEFAULT 3,
    
    -- 💳 Datos de transacción
    metodo_pago TEXT,
    transaction_id TEXT, -- ID de la transacción en ePayco
    ref_payco TEXT, -- Referencia única de ePayco
    datos_pago JSONB DEFAULT '{}'::jsonb,
    
    -- 📝 Información adicional
    notas_admin TEXT, -- Notas internas del administrador
    razon_cancelacion TEXT, -- Motivo de cancelación
    origen_suscripcion TEXT DEFAULT 'web' 
        CHECK (origen_suscripcion IN ('web', 'admin', 'promocion', 'migracion')),
    
    -- ⏰ Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ====================================
-- 2️⃣ CREAR ÍNDICES PARA OPTIMIZACIÓN
-- ====================================

-- Índice principal para buscar suscripción activa de un usuario
CREATE INDEX IF NOT EXISTS idx_suscripciones_usuario_activa 
    ON suscripciones_usuario(usuario_id, estado) 
    WHERE estado = 'activa';

-- Índice para buscar por usuario
CREATE INDEX IF NOT EXISTS idx_suscripciones_usuario_id 
    ON suscripciones_usuario(usuario_id);

-- Índice para buscar por membresía
CREATE INDEX IF NOT EXISTS idx_suscripciones_membresia_id 
    ON suscripciones_usuario(membresia_id);

-- Índice para suscripciones que vencen pronto
CREATE INDEX IF NOT EXISTS idx_suscripciones_vencimiento 
    ON suscripciones_usuario(fecha_vencimiento, estado) 
    WHERE estado = 'activa';

-- Índice para buscar por transaction_id
CREATE INDEX IF NOT EXISTS idx_suscripciones_transaction 
    ON suscripciones_usuario(transaction_id) 
    WHERE transaction_id IS NOT NULL;

-- Índice para reportes por fecha
CREATE INDEX IF NOT EXISTS idx_suscripciones_fecha_inicio 
    ON suscripciones_usuario(fecha_inicio, membresia_id);

-- ====================================
-- 3️⃣ CREAR CONSTRAINT ÚNICO
-- ====================================

-- Un usuario solo puede tener UNA suscripción activa a la vez
CREATE UNIQUE INDEX IF NOT EXISTS idx_suscripciones_usuario_activa_unica 
    ON suscripciones_usuario(usuario_id) 
    WHERE estado = 'activa';

-- ====================================
-- 4️⃣ CREAR TRIGGER DE UPDATED_AT
-- ====================================

CREATE OR REPLACE FUNCTION actualizar_updated_at_suscripciones()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_suscripciones_updated_at ON suscripciones_usuario;
CREATE TRIGGER trigger_suscripciones_updated_at
    BEFORE UPDATE ON suscripciones_usuario
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at_suscripciones();

-- ====================================
-- 5️⃣ FUNCIÓN PARA OBTENER MEMBRESÍA ACTIVA
-- ====================================

CREATE OR REPLACE FUNCTION obtener_membresia_activa(p_usuario_id UUID)
RETURNS TABLE (
    suscripcion_id UUID,
    membresia_nombre TEXT,
    membresia_id UUID,
    estado TEXT,
    fecha_vencimiento DATE,
    dias_restantes INTEGER,
    precio_pagado DECIMAL,
    periodo TEXT,
    permisos JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        su.id as suscripcion_id,
        m.nombre as membresia_nombre,
        m.id as membresia_id,
        su.estado,
        su.fecha_vencimiento,
        (su.fecha_vencimiento - CURRENT_DATE) as dias_restantes,
        su.precio_pagado,
        su.periodo,
        m.permisos
    FROM suscripciones_usuario su
    JOIN membresias m ON su.membresia_id = m.id
    WHERE su.usuario_id = p_usuario_id 
      AND su.estado = 'activa'
      AND su.fecha_vencimiento >= CURRENT_DATE
    ORDER BY su.fecha_vencimiento DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 6️⃣ FUNCIÓN PARA VERIFICAR ACCESO A RECURSO
-- ====================================

CREATE OR REPLACE FUNCTION usuario_tiene_acceso(
    p_usuario_id UUID, 
    p_tipo_recurso TEXT,
    p_recurso_especifico TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    membresia_permisos JSONB;
    acceso_permitido BOOLEAN := false;
BEGIN
    -- Obtener permisos de la membresía activa
    SELECT m.permisos INTO membresia_permisos
    FROM suscripciones_usuario su
    JOIN membresias m ON su.membresia_id = m.id
    WHERE su.usuario_id = p_usuario_id 
      AND su.estado = 'activa'
      AND su.fecha_vencimiento >= CURRENT_DATE
    LIMIT 1;
    
    -- Si no tiene membresía activa, no tiene acceso
    IF membresia_permisos IS NULL THEN
        RETURN false;
    END IF;
    
    -- Verificar acceso según el tipo de recurso
    CASE p_tipo_recurso
        WHEN 'simulador_basico' THEN
            acceso_permitido := (membresia_permisos->'simulador'->>'tipo' IS NOT NULL);
            
        WHEN 'simulador_avanzado' THEN
            acceso_permitido := (membresia_permisos->'simulador'->>'tipo' IN ('completo', 'elite'));
            
        WHEN 'tutoriales' THEN
            acceso_permitido := (
                membresia_permisos->'contenido'->>'tutoriales_acceso' = 'completo' OR
                membresia_permisos->'contenido'->>'tutoriales_premium' = 'true'
            );
            
        WHEN 'cursos' THEN
            acceso_permitido := (membresia_permisos->'contenido'->>'cursos_acceso' = 'completo');
            
        WHEN 'eventos_vivo' THEN
            acceso_permitido := (membresia_permisos->'contenido'->>'eventos_en_vivo' = 'true');
            
        WHEN 'clases_personalizadas' THEN
            acceso_permitido := (membresia_permisos->'contenido'->>'clases_1on1' IS NOT NULL);
            
        WHEN 'comunidad' THEN
            acceso_permitido := (membresia_permisos->'comunidad'->>'acceso_completo' = 'true');
            
        ELSE
            acceso_permitido := false;
    END CASE;
    
    RETURN acceso_permitido;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 7️⃣ FUNCIÓN PARA ACTUALIZAR ESTADOS VENCIDOS
-- ====================================

CREATE OR REPLACE FUNCTION actualizar_suscripciones_vencidas()
RETURNS INTEGER AS $$
DECLARE
    suscripciones_actualizadas INTEGER := 0;
BEGIN
    -- Marcar como vencidas las suscripciones que ya pasaron su fecha
    UPDATE suscripciones_usuario 
    SET 
        estado = 'vencida',
        updated_at = NOW()
    WHERE estado = 'activa' 
      AND fecha_vencimiento < CURRENT_DATE;
    
    GET DIAGNOSTICS suscripciones_actualizadas = ROW_COUNT;
    
    RETURN suscripciones_actualizadas;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 8️⃣ FUNCIÓN PARA CREAR NUEVA SUSCRIPCIÓN
-- ====================================

CREATE OR REPLACE FUNCTION crear_suscripcion(
    p_usuario_id UUID,
    p_membresia_id UUID,
    p_periodo TEXT DEFAULT 'mensual',
    p_precio_pagado DECIMAL DEFAULT NULL,
    p_transaction_id TEXT DEFAULT NULL,
    p_metodo_pago TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    nueva_suscripcion_id UUID;
    precio_membresia DECIMAL;
    fecha_venc DATE;
BEGIN
    -- Cancelar suscripción activa previa si existe
    UPDATE suscripciones_usuario 
    SET estado = 'cancelada', 
        fecha_cancelacion = NOW(),
        razon_cancelacion = 'Upgrade/cambio de plan'
    WHERE usuario_id = p_usuario_id 
      AND estado = 'activa';
    
    -- Obtener precio de la membresía según el período
    SELECT 
        CASE 
            WHEN p_periodo = 'anual' THEN precio_anual
            ELSE precio_mensual 
        END INTO precio_membresia
    FROM membresias 
    WHERE id = p_membresia_id;
    
    -- Calcular fecha de vencimiento
    fecha_venc := CASE 
        WHEN p_periodo = 'anual' THEN CURRENT_DATE + INTERVAL '1 year'
        ELSE CURRENT_DATE + INTERVAL '1 month'
    END;
    
    -- Crear nueva suscripción
    INSERT INTO suscripciones_usuario (
        usuario_id,
        membresia_id,
        periodo,
        precio_pagado,
        fecha_vencimiento,
        transaction_id,
        metodo_pago,
        origen_suscripcion
    ) VALUES (
        p_usuario_id,
        p_membresia_id,
        p_periodo,
        COALESCE(p_precio_pagado, precio_membresia),
        fecha_venc,
        p_transaction_id,
        p_metodo_pago,
        'web'
    ) RETURNING id INTO nueva_suscripcion_id;
    
    RETURN nueva_suscripcion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- 9️⃣ CREAR ALGUNAS SUSCRIPCIONES DE PRUEBA
-- ====================================

-- Insertar suscripción de prueba para el usuario admin (si existe)
DO $$
DECLARE
    admin_user_id UUID;
    membresia_premium_id UUID;
    suscripcion_id UUID;
BEGIN
    -- Buscar usuario admin
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email LIKE '%admin%' OR email LIKE '%test%'
    LIMIT 1;
    
    -- Buscar membresía Premium
    SELECT id INTO membresia_premium_id 
    FROM membresias 
    WHERE nombre = 'Premium';
    
    -- Solo crear si encontramos ambos
    IF admin_user_id IS NOT NULL AND membresia_premium_id IS NOT NULL THEN
        SELECT crear_suscripcion(
            admin_user_id,
            membresia_premium_id,
            'mensual',
            120000.00,
            'TEST_TRANSACTION_001',
            'Tarjeta de Crédito'
        ) INTO suscripcion_id;
        
        RAISE NOTICE '✅ Suscripción de prueba creada para admin: %', suscripcion_id;
    ELSE
        RAISE NOTICE '⚠️ No se pudo crear suscripción de prueba (usuario admin no encontrado)';
    END IF;
END $$;

-- ====================================
-- 🔟 VERIFICACIONES Y VALIDACIONES
-- ====================================

-- Verificar estructura de la tabla
DO $$
DECLARE
    total_indices INTEGER;
    total_funciones INTEGER;
    ejemplo_suscripcion RECORD;
BEGIN
    -- Contar índices creados
    SELECT COUNT(*) INTO total_indices
    FROM pg_indexes 
    WHERE tablename = 'suscripciones_usuario';
    
    RAISE NOTICE '📊 Índices creados: %', total_indices;
    
    -- Verificar funciones creadas
    SELECT COUNT(*) INTO total_funciones
    FROM pg_proc 
    WHERE proname IN (
        'obtener_membresia_activa',
        'usuario_tiene_acceso', 
        'actualizar_suscripciones_vencidas',
        'crear_suscripcion'
    );
    
    RAISE NOTICE '⚙️ Funciones creadas: %', total_funciones;
    
    -- Mostrar ejemplo de suscripción si existe
    SELECT 
        su.id,
        m.nombre as membresia,
        su.estado,
        su.fecha_vencimiento
    INTO ejemplo_suscripcion
    FROM suscripciones_usuario su
    JOIN membresias m ON su.membresia_id = m.id
    LIMIT 1;
    
    IF ejemplo_suscripcion.id IS NOT NULL THEN
        RAISE NOTICE '🎯 Ejemplo de suscripción: % (%) - Estado: % - Vence: %', 
            ejemplo_suscripcion.id,
            ejemplo_suscripcion.membresia,
            ejemplo_suscripcion.estado,
            ejemplo_suscripcion.fecha_vencimiento;
    END IF;
    
    RAISE NOTICE '✅ ¡Tabla de suscripciones creada exitosamente!';
END $$;

-- ====================================
-- 1️⃣1️⃣ COMENTARIOS FINALES
-- ====================================

COMMENT ON TABLE suscripciones_usuario IS 'Tabla que maneja las suscripciones activas e historial de cada usuario';
COMMENT ON COLUMN suscripciones_usuario.estado IS 'Estado actual: activa, pausada, cancelada, vencida, pendiente_pago';
COMMENT ON COLUMN suscripciones_usuario.auto_renovar IS 'Si debe intentar renovarse automáticamente al vencer';
COMMENT ON COLUMN suscripciones_usuario.datos_pago IS 'Información adicional del pago en formato JSON';
COMMENT ON COLUMN suscripciones_usuario.origen_suscripcion IS 'Cómo se originó: web, admin, promocion, migracion';

-- ====================================
-- ✅ SCRIPT COMPLETADO
-- ====================================

SELECT 
    '🎉 ¡FASE 1.2 COMPLETADA EXITOSAMENTE!' as mensaje,
    COUNT(*) as suscripciones_creadas,
    COUNT(CASE WHEN estado = 'activa' THEN 1 END) as suscripciones_activas
FROM suscripciones_usuario; 