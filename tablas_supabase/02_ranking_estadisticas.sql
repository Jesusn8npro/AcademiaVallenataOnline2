-- =====================================================
-- 🎮 PARTE 2: RANKING Y ESTADÍSTICAS
-- =====================================================
-- Ejecutar después de la PARTE 1

-- Tabla de ranking global
CREATE TABLE IF NOT EXISTS public.ranking_global (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo_ranking TEXT NOT NULL CHECK (tipo_ranking IN ('general', 'semanal', 'mensual', 'simulador', 'cursos', 'precision', 'constancia', 'comunidad', 'especial')),
    puntuacion INTEGER DEFAULT 0,
    posicion INTEGER DEFAULT 0,
    posicion_anterior INTEGER,
    metricas JSONB DEFAULT '{}',
    periodo_inicio TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    periodo_fin TIMESTAMP WITH TIME ZONE,
    temporada TEXT,
    activo BOOLEAN DEFAULT TRUE,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(usuario_id, tipo_ranking)
);

-- Tabla de estadísticas de usuario
CREATE TABLE IF NOT EXISTS public.estadisticas_usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_sesiones INTEGER DEFAULT 0,
    tiempo_total_minutos INTEGER DEFAULT 0,
    primer_sesion TIMESTAMP WITH TIME ZONE,
    ultima_sesion TIMESTAMP WITH TIME ZONE,
    precision_maxima DECIMAL(5,2) DEFAULT 0.0,
    precision_promedio DECIMAL(5,2) DEFAULT 0.0,
    notas_totales_tocadas INTEGER DEFAULT 0,
    notas_correctas_totales INTEGER DEFAULT 0,
    cursos_completados INTEGER DEFAULT 0,
    tutoriales_completados INTEGER DEFAULT 0,
    lecciones_completadas INTEGER DEFAULT 0,
    publicaciones_creadas INTEGER DEFAULT 0,
    likes_recibidos INTEGER DEFAULT 0,
    comentarios_hechos INTEGER DEFAULT 0,
    logros_totales INTEGER DEFAULT 0,
    logros_faciles INTEGER DEFAULT 0,
    logros_medios INTEGER DEFAULT 0,
    logros_dificiles INTEGER DEFAULT 0,
    logros_legendarios INTEGER DEFAULT 0,
    racha_actual_dias INTEGER DEFAULT 0,
    racha_maxima_dias INTEGER DEFAULT 0,
    dias_activos_total INTEGER DEFAULT 0,
    mejor_posicion_global INTEGER,
    mejor_posicion_semanal INTEGER,
    semanas_en_top_10 INTEGER DEFAULT 0,
    calculado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(usuario_id)
);

-- Tabla de sesiones del simulador
CREATE TABLE IF NOT EXISTS public.sesiones_simulador (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    duracion_minutos INTEGER DEFAULT 0,
    duracion_segundos INTEGER DEFAULT 0,
    tiempo_inicio TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    tiempo_fin TIMESTAMP WITH TIME ZONE,
    notas_tocadas INTEGER DEFAULT 0,
    notas_correctas INTEGER DEFAULT 0,
    notas_incorrectas INTEGER DEFAULT 0,
    precision_promedio DECIMAL(5,2) DEFAULT 0.0,
    bpm_promedio INTEGER DEFAULT 0,
    escalas_practicadas TEXT[] DEFAULT '{}',
    acordes_practicados TEXT[] DEFAULT '{}',
    canciones_intentadas TEXT[] DEFAULT '{}',
    afinacion_usada TEXT DEFAULT 'standard',
    tipo_practica TEXT DEFAULT 'libre' CHECK (tipo_practica IN ('libre', 'leccion', 'cancion', 'escala', 'ejercicio')),
    xp_ganado INTEGER DEFAULT 0,
    logros_desbloqueados TEXT[] DEFAULT '{}',
    nivel_antes INTEGER DEFAULT 1,
    nivel_despues INTEGER DEFAULT 1,
    datos_sesion JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 📊 TRIGGERS PARA TIMESTAMPS
-- =====================================================

DROP TRIGGER IF EXISTS trigger_ranking_updated_at ON public.ranking_global;
CREATE TRIGGER trigger_ranking_updated_at
    BEFORE UPDATE ON public.ranking_global
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

DROP TRIGGER IF EXISTS trigger_estadisticas_updated_at ON public.estadisticas_usuario;
CREATE TRIGGER trigger_estadisticas_updated_at
    BEFORE UPDATE ON public.estadisticas_usuario
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- =====================================================
-- 🔒 RLS PARA RANKING GLOBAL
-- =====================================================

ALTER TABLE public.ranking_global ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver el ranking global"
    ON public.ranking_global
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Los usuarios pueden actualizar su propio ranking"
    ON public.ranking_global
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "El sistema puede insertar ranking para cualquier usuario"
    ON public.ranking_global
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- =====================================================
-- 🔒 RLS PARA ESTADÍSTICAS USUARIO
-- =====================================================

ALTER TABLE public.estadisticas_usuario ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver sus propias estadísticas"
    ON public.estadisticas_usuario
    FOR SELECT
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "Los usuarios pueden actualizar sus propias estadísticas"
    ON public.estadisticas_usuario
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "El sistema puede insertar estadísticas para cualquier usuario"
    ON public.estadisticas_usuario
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- =====================================================
-- 🔒 RLS PARA SESIONES SIMULADOR
-- =====================================================

ALTER TABLE public.sesiones_simulador ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver sus propias sesiones"
    ON public.sesiones_simulador
    FOR SELECT
    TO authenticated
    USING (auth.uid() = usuario_id);

CREATE POLICY "Los usuarios pueden insertar sus propias sesiones"
    ON public.sesiones_simulador
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = usuario_id);

-- =====================================================
-- 📊 ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_experiencia_usuario_id ON public.experiencia_usuario(usuario_id);
CREATE INDEX IF NOT EXISTS idx_experiencia_nivel ON public.experiencia_usuario(nivel DESC);
CREATE INDEX IF NOT EXISTS idx_experiencia_xp_total ON public.experiencia_usuario(xp_total DESC);

CREATE INDEX IF NOT EXISTS idx_ranking_usuario_tipo ON public.ranking_global(usuario_id, tipo_ranking);
CREATE INDEX IF NOT EXISTS idx_ranking_tipo_posicion ON public.ranking_global(tipo_ranking, posicion);
CREATE INDEX IF NOT EXISTS idx_ranking_puntuacion ON public.ranking_global(puntuacion DESC);
CREATE INDEX IF NOT EXISTS idx_ranking_activo ON public.ranking_global(activo);

CREATE INDEX IF NOT EXISTS idx_estadisticas_usuario_id ON public.estadisticas_usuario(usuario_id);
CREATE INDEX IF NOT EXISTS idx_estadisticas_cursos ON public.estadisticas_usuario(cursos_completados DESC);
CREATE INDEX IF NOT EXISTS idx_estadisticas_tutoriales ON public.estadisticas_usuario(tutoriales_completados DESC);

CREATE INDEX IF NOT EXISTS idx_sesiones_usuario_id ON public.sesiones_simulador(usuario_id);
CREATE INDEX IF NOT EXISTS idx_sesiones_created_at ON public.sesiones_simulador(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_logros_usuario_conseguido ON public.logros_usuario(usuario_id, conseguido);

-- =====================================================
-- ✅ COMPLETADO PARTE 2
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ PARTE 2 COMPLETADA: Ranking y estadísticas creadas';
    RAISE NOTICE '▶️  EJECUTAR SIGUIENTE: 03_logros_triggers.sql';
END $$; 