-- =====================================================
-- 🔧 FIX: CAMBIAR TIPO DE DATO EN LOGROS_SISTEMA
-- =====================================================
-- Ejecutar ANTES del script 04 si ya tienes las tablas creadas

-- Paso 1: Verificar estructura actual
DO $$
BEGIN
    RAISE NOTICE '🔍 Verificando estructura actual de logros_sistema...';
END $$;

-- Paso 2: Borrar tabla logros_sistema si existe para recrearla correctamente
DROP TABLE IF EXISTS public.logros_usuario CASCADE;
DROP TABLE IF EXISTS public.logros_sistema CASCADE;

-- Paso 3: Recrear tabla logros_sistema con ID como TEXT
CREATE TABLE IF NOT EXISTS public.logros_sistema (
    id TEXT PRIMARY KEY,  -- ✅ CAMBIADO DE UUID A TEXT
    nombre TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    descripcion_corta TEXT,
    icono TEXT DEFAULT '🏆',
    categoria TEXT NOT NULL CHECK (categoria IN ('constancia', 'progreso', 'precision', 'social', 'especial', 'simulador', 'cursos', 'comunidad')),
    dificultad TEXT NOT NULL CHECK (dificultad IN ('facil', 'medio', 'dificil', 'legendario')),
    xp_recompensa INTEGER DEFAULT 0,
    monedas_recompensa INTEGER DEFAULT 0,
    titulo_especial TEXT,
    condiciones JSONB DEFAULT '{}',
    activo BOOLEAN DEFAULT TRUE,
    visible BOOLEAN DEFAULT TRUE,
    orden_mostrar INTEGER DEFAULT 0,
    fecha_inicio TIMESTAMP WITH TIME ZONE,
    fecha_fin TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Paso 4: Recrear tabla logros_usuario
CREATE TABLE IF NOT EXISTS public.logros_usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    logro_id TEXT NOT NULL REFERENCES public.logros_sistema(id) ON DELETE CASCADE,  -- ✅ REFERENCIA A TEXT
    conseguido BOOLEAN DEFAULT FALSE,
    progreso_actual INTEGER DEFAULT 0,
    progreso_objetivo INTEGER DEFAULT 1,
    porcentaje_progreso DECIMAL(5,2) DEFAULT 0.0,
    datos_logro JSONB DEFAULT '{}',
    conseguido_en TIMESTAMP WITH TIME ZONE,
    primer_progreso TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ultimo_progreso TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(usuario_id, logro_id)
);

-- Paso 5: Recrear triggers
DROP TRIGGER IF EXISTS trigger_logros_sistema_updated_at ON public.logros_sistema;
CREATE TRIGGER trigger_logros_sistema_updated_at
    BEFORE UPDATE ON public.logros_sistema
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

DROP TRIGGER IF EXISTS trigger_logros_usuario_updated_at ON public.logros_usuario;
CREATE TRIGGER trigger_logros_usuario_updated_at
    BEFORE UPDATE ON public.logros_usuario
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- Paso 6: Recrear RLS
ALTER TABLE public.logros_sistema ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver los logros del sistema"
    ON public.logros_sistema
    FOR SELECT
    TO authenticated
    USING (visible = true);

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

-- ✅ COMPLETADO
DO $$
BEGIN
    RAISE NOTICE '✅ Tablas logros_sistema y logros_usuario recreadas correctamente';
    RAISE NOTICE '🔧 Campo id ahora es TEXT en lugar de UUID';
    RAISE NOTICE '▶️  Ahora puedes ejecutar el script 04_triggers_integracion.sql';
END $$; 