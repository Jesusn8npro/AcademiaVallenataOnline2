-- =====================================================
-- 🎮 PARTE 1: TABLAS PRINCIPALES DE GAMIFICACIÓN
-- =====================================================
-- Ejecutar primero esta parte

-- Tabla de experiencia de usuario
CREATE TABLE IF NOT EXISTS public.experiencia_usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nivel INTEGER DEFAULT 1,
    xp_actual INTEGER DEFAULT 0,
    xp_total INTEGER DEFAULT 0,
    xp_siguiente_nivel INTEGER DEFAULT 100,
    xp_cursos INTEGER DEFAULT 0,
    xp_simulador INTEGER DEFAULT 0,
    xp_comunidad INTEGER DEFAULT 0,
    xp_logros INTEGER DEFAULT 0,
    racha_dias INTEGER DEFAULT 0,
    racha_maxima INTEGER DEFAULT 0,
    ultima_sesion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(usuario_id)
);

-- Tabla de logros del sistema
CREATE TABLE IF NOT EXISTS public.logros_sistema (
    id TEXT PRIMARY KEY,  -- ✅ TEXT para usar IDs descriptivos
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

-- Tabla de logros de usuario
CREATE TABLE IF NOT EXISTS public.logros_usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    logro_id TEXT NOT NULL REFERENCES public.logros_sistema(id) ON DELETE CASCADE,  -- ✅ TEXT FK
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

-- =====================================================
-- 🔄 FUNCIÓN PARA ACTUALIZAR TIMESTAMPS
-- =====================================================

CREATE OR REPLACE FUNCTION actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 📊 TRIGGERS PARA TIMESTAMPS
-- =====================================================

DROP TRIGGER IF EXISTS trigger_experiencia_updated_at ON public.experiencia_usuario;
CREATE TRIGGER trigger_experiencia_updated_at
    BEFORE UPDATE ON public.experiencia_usuario
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

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

-- =====================================================
-- 🔒 RLS PARA EXPERIENCIA USUARIO
-- =====================================================

ALTER TABLE public.experiencia_usuario ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver su propia experiencia"
    ON public.experiencia_usuario
    FOR SELECT
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "Los usuarios pueden actualizar su propia experiencia"
    ON public.experiencia_usuario
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "El sistema puede insertar experiencia para cualquier usuario"
    ON public.experiencia_usuario
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- =====================================================
-- ✅ COMPLETADO PARTE 1
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ PARTE 1 COMPLETADA: Tablas principales creadas';
    RAISE NOTICE '▶️  EJECUTAR SIGUIENTE: 02_ranking_estadisticas.sql';
END $$; 