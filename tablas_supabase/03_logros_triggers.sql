-- =====================================================
-- 🎮 PARTE 3: LOGROS Y TRIGGERS
-- =====================================================
-- Ejecutar después de la PARTE 2

-- Tabla de notificaciones gaming
CREATE TABLE IF NOT EXISTS public.notificaciones_gaming (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN ('logro_conseguido', 'subida_nivel', 'nuevo_ranking', 'racha_perdida', 'desafio_completado', 'monedas_ganadas', 'evento_especial', 'meta_alcanzada')),
    titulo TEXT NOT NULL,
    mensaje TEXT NOT NULL,
    icono TEXT DEFAULT '🎮',
    datos_notificacion JSONB DEFAULT '{}',
    leida BOOLEAN DEFAULT FALSE,
    mostrada BOOLEAN DEFAULT FALSE,
    accion_realizada BOOLEAN DEFAULT FALSE,
    prioridad TEXT DEFAULT 'normal' CHECK (prioridad IN ('baja', 'normal', 'alta', 'critica')),
    estilo_visual TEXT DEFAULT 'normal' CHECK (estilo_visual IN ('normal', 'celebracion', 'logro', 'ranking', 'especial')),
    fecha_expiracion TIMESTAMP WITH TIME ZONE,
    leida_en TIMESTAMP WITH TIME ZONE,
    mostrada_en TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de actividades pendientes para procesamiento
CREATE TABLE IF NOT EXISTS public.actividades_pendientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo_actividad TEXT NOT NULL,
    datos_actividad JSONB DEFAULT '{}',
    procesado BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 📊 TRIGGERS PARA TIMESTAMPS
-- =====================================================

DROP TRIGGER IF EXISTS trigger_notificaciones_updated_at ON public.notificaciones_gaming;
CREATE TRIGGER trigger_notificaciones_updated_at
    BEFORE UPDATE ON public.notificaciones_gaming
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- =====================================================
-- 🔒 RLS PARA NOTIFICACIONES GAMING
-- =====================================================

ALTER TABLE public.notificaciones_gaming ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver sus propias notificaciones"
    ON public.notificaciones_gaming
    FOR SELECT
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "Los usuarios pueden actualizar sus propias notificaciones"
    ON public.notificaciones_gaming
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "El sistema puede insertar notificaciones para cualquier usuario"
    ON public.notificaciones_gaming
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- =====================================================
-- 🔒 RLS PARA ACTIVIDADES PENDIENTES
-- =====================================================

ALTER TABLE public.actividades_pendientes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver sus propias actividades pendientes"
    ON public.actividades_pendientes
    FOR SELECT
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "El sistema puede insertar actividades pendientes"
    ON public.actividades_pendientes
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "El sistema puede actualizar actividades pendientes"
    ON public.actividades_pendientes
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = usuario_id);

-- =====================================================
-- 🔒 RLS PARA LOGROS SISTEMA
-- =====================================================

ALTER TABLE public.logros_sistema ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver los logros del sistema"
    ON public.logros_sistema
    FOR SELECT
    TO authenticated
    USING (visible = true);

-- =====================================================
-- 🔒 RLS PARA LOGROS USUARIO
-- =====================================================

ALTER TABLE public.logros_usuario ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver sus propios logros"
    ON public.logros_usuario
    FOR SELECT
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "El sistema puede insertar logros para cualquier usuario"
    ON public.logros_usuario
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "El sistema puede actualizar logros de usuarios"
    ON public.logros_usuario
    FOR UPDATE
    TO authenticated
    USING (true);

-- =====================================================
-- 📊 ÍNDICES ADICIONALES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_id ON public.notificaciones_gaming(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notificaciones_leida ON public.notificaciones_gaming(leida);
CREATE INDEX IF NOT EXISTS idx_notificaciones_created_at ON public.notificaciones_gaming(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_actividades_pendientes_usuario ON public.actividades_pendientes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_actividades_pendientes_procesado ON public.actividades_pendientes(procesado);

-- =====================================================
-- 🔄 FUNCIÓN PARA PROCESAR ACTIVIDAD DE USUARIO
-- =====================================================

CREATE OR REPLACE FUNCTION procesar_actividad_usuario()
RETURNS TRIGGER AS $$
BEGIN
    -- Llamar función para sincronizar datos reales con gamificación
    PERFORM procesar_actividad_gamificacion(NEW.usuario_id, TG_ARGV[0], to_jsonb(NEW));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 🔄 FUNCIÓN PARA PROCESAR ACTIVIDAD DE GAMIFICACIÓN
-- =====================================================

CREATE OR REPLACE FUNCTION procesar_actividad_gamificacion(
    p_usuario_id UUID,
    p_tipo_actividad TEXT,
    p_datos_actividad JSONB
)
RETURNS VOID AS $$
BEGIN
    -- Esta función será llamada desde el frontend
    -- Aquí solo insertamos un registro para procesamiento asíncrono
    INSERT INTO public.actividades_pendientes (usuario_id, tipo_actividad, datos_actividad, created_at)
    VALUES (p_usuario_id, p_tipo_actividad, p_datos_actividad, NOW())
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 📊 FUNCIÓN PARA OBTENER ACTIVIDADES PENDIENTES
-- =====================================================

CREATE OR REPLACE FUNCTION obtener_actividades_pendientes(p_usuario_id UUID)
RETURNS TABLE (
    id UUID,
    tipo_actividad TEXT,
    datos_actividad JSONB,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ap.id,
        ap.tipo_actividad,
        ap.datos_actividad,
        ap.created_at
    FROM public.actividades_pendientes ap
    WHERE ap.usuario_id = p_usuario_id 
    AND ap.procesado = FALSE
    ORDER BY ap.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 📊 FUNCIÓN PARA MARCAR ACTIVIDAD COMO PROCESADA
-- =====================================================

CREATE OR REPLACE FUNCTION marcar_actividad_procesada(p_actividad_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.actividades_pendientes
    SET procesado = TRUE
    WHERE id = p_actividad_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ✅ COMPLETADO PARTE 3
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ PARTE 3 COMPLETADA: Logros y triggers creados';
    RAISE NOTICE '▶️  EJECUTAR SIGUIENTE: 04_triggers_integracion.sql';
END $$; 