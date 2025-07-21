-- =====================================================
-- 🎵 SISTEMA DE CANCIONES PARA SIMULADOR DE ACORDEÓN
-- =====================================================
-- Integración con sistema de gamificación existente
-- Estilo Guitar Hero para acordeón vallenato
-- Autor: Academia Vallenata Online
-- Fecha: Diciembre 2024
-- =====================================================

-- =====================================================
-- 🎶 TABLA: canciones_simulador_acordeon
-- =====================================================
-- Catálogo de canciones para el simulador
-- Información básica y metadatos
-- =====================================================

CREATE TABLE IF NOT EXISTS canciones_simulador_acordeon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Información básica
    titulo VARCHAR(200) NOT NULL,
    artista VARCHAR(200) NOT NULL,
    genero TEXT DEFAULT 'vallenato' CHECK (genero IN ('vallenato', 'cumbia', 'merengue', 'paseo', 'puya', 'son')),
    
    -- Configuración musical
    nivel_dificultad INTEGER NOT NULL DEFAULT 1 CHECK (nivel_dificultad >= 1 AND nivel_dificultad <= 10),
    duracion_segundos INTEGER NOT NULL CHECK (duracion_segundos > 0),
    bpm INTEGER CHECK (bpm > 0 AND bpm <= 300),
    afinacion TEXT DEFAULT 'FBE' CHECK (afinacion IN ('FBE', 'GCF', 'ADG', 'EAD')),
    
    -- Archivos de audio
    url_audio TEXT NOT NULL, -- URL del archivo principal
    url_audio_backing TEXT, -- Pista sin acordeón (opcional)
    url_audio_preview TEXT, -- Preview corto (30 segundos)
    
    -- Metadatos adicionales
    descripcion TEXT,
    letra TEXT,
    tags TEXT[], -- ['principiante', 'popular', 'tradicional']
    
    -- Configuración de dificultad
    dificultad_tecnica TEXT DEFAULT 'principiante' CHECK (dificultad_tecnica IN ('principiante', 'intermedio', 'avanzado', 'experto')),
    requiere_cambios_fuelle BOOLEAN DEFAULT TRUE,
    requiere_acordes BOOLEAN DEFAULT FALSE,
    requiere_bajos BOOLEAN DEFAULT TRUE,
    
    -- Gamificación
    xp_recompensa INTEGER DEFAULT 0 CHECK (xp_recompensa >= 0),
    monedas_recompensa INTEGER DEFAULT 0 CHECK (monedas_recompensa >= 0),
    puntos_precision INTEGER DEFAULT 0 CHECK (puntos_precision >= 0),
    
    -- Configuración de juego
    tiempo_maximo_minutos INTEGER DEFAULT 10 CHECK (tiempo_maximo_minutos > 0),
    precision_minima_requerida INTEGER DEFAULT 75 CHECK (precision_minima_requerida >= 0 AND precision_minima_requerida <= 100),
    intentos_maximos INTEGER DEFAULT 5 CHECK (intentos_maximos > 0),
    
    -- Estado y visibilidad
    estado TEXT DEFAULT 'activa' CHECK (estado IN ('borrador', 'activa', 'pausada', 'archivada')),
    es_publica BOOLEAN DEFAULT TRUE,
    es_premium BOOLEAN DEFAULT FALSE,
    orden_mostrar INTEGER DEFAULT 0,
    
    -- Creador
    creador_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
    
    -- Metadatos
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comentarios de tabla
COMMENT ON TABLE canciones_simulador_acordeon IS '🎶 Catálogo de canciones para el simulador tipo Guitar Hero';
COMMENT ON COLUMN canciones_simulador_acordeon.url_audio IS 'URL del archivo de audio principal';
COMMENT ON COLUMN canciones_simulador_acordeon.url_audio_backing IS 'Pista sin acordeón para práctica';
COMMENT ON COLUMN canciones_simulador_acordeon.afinacion IS 'Afinación del acordeón requerida';

-- =====================================================
-- 🎼 TABLA: secuencias_canciones_acordeon
-- =====================================================
-- Secuencias de notas sincronizadas con el audio
-- Patrón de referencia para la práctica
-- =====================================================

CREATE TABLE IF NOT EXISTS secuencias_canciones_acordeon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cancion_id UUID NOT NULL REFERENCES canciones_simulador_acordeon(id) ON DELETE CASCADE,
    
    -- Información de la secuencia
    nombre_secuencia VARCHAR(100) DEFAULT 'Secuencia principal',
    descripcion TEXT,
    
    -- Configuración de timing
    tolerancia_timing_ms INTEGER DEFAULT 150 CHECK (tolerancia_timing_ms >= 50 AND tolerancia_timing_ms <= 500),
    auto_cuantizar BOOLEAN DEFAULT FALSE,
    usar_metronomo BOOLEAN DEFAULT FALSE,
    
    -- Secuencia de notas (JSON)
    notas_secuencia JSONB NOT NULL DEFAULT '[]',
    /* Estructura JSON:
    [
        {
            "timestamp_ms": 1500,
            "duracion_ms": 400,
            "nota_id": "primeraFila-1-halar",
            "nota_nombre": "Do",
            "fuelle_direccion": "halar",
            "es_acorde": false,
            "notas_acorde": [],
            "intensidad": "normal",
            "es_opcional": false,
            "tipo_nota": "melodia" // o "bajo"
        }
    ]
    */
    
    -- Marcadores de tiempo
    marcadores_tiempo JSONB DEFAULT '{}',
    /* Estructura JSON:
    {
        "intro_hasta_segundo": 8,
        "verso_desde_segundo": 8,
        "verso_hasta_segundo": 30,
        "coro_desde_segundo": 30,
        "coro_hasta_segundo": 60,
        "outro_desde_segundo": 90
    }
    */
    
    -- Estadísticas de la secuencia
    total_notas INTEGER GENERATED ALWAYS AS (jsonb_array_length(notas_secuencia)) STORED,
    duracion_total_ms INTEGER,
    
    -- Configuración de dificultad
    es_secuencia_principal BOOLEAN DEFAULT TRUE,
    nivel_dificultad INTEGER DEFAULT 1 CHECK (nivel_dificultad >= 1 AND nivel_dificultad <= 10),
    
    -- Estado
    estado TEXT DEFAULT 'activa' CHECK (estado IN ('borrador', 'activa', 'pausada')),
    
    -- Metadatos
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(cancion_id, nombre_secuencia)
);

-- Comentarios de tabla
COMMENT ON TABLE secuencias_canciones_acordeon IS '🎼 Secuencias de notas sincronizadas con canciones';
COMMENT ON COLUMN secuencias_canciones_acordeon.notas_secuencia IS 'Array JSON con las notas y sus timestamps';
COMMENT ON COLUMN secuencias_canciones_acordeon.marcadores_tiempo IS 'Marcadores de secciones de la canción';

-- =====================================================
-- 📈 TABLA: progreso_canciones_acordeon
-- =====================================================
-- Progreso de usuarios en canciones específicas
-- Integración con sistema de gamificación
-- =====================================================

CREATE TABLE IF NOT EXISTS progreso_canciones_acordeon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
    cancion_id UUID NOT NULL REFERENCES canciones_simulador_acordeon(id) ON DELETE CASCADE,
    
    -- Estado del progreso
    estado TEXT DEFAULT 'iniciado' CHECK (estado IN ('iniciado', 'en_progreso', 'completado', 'perfecto')),
    
    -- Estadísticas de progreso
    mejor_precision NUMERIC(5,2) DEFAULT 0 CHECK (mejor_precision >= 0 AND mejor_precision <= 100),
    precision_actual NUMERIC(5,2) DEFAULT 0 CHECK (precision_actual >= 0 AND precision_actual <= 100),
    intentos_realizados INTEGER DEFAULT 0 CHECK (intentos_realizados >= 0),
    tiempo_practicado_minutos INTEGER DEFAULT 0 CHECK (tiempo_practicado_minutos >= 0),
    
    -- Métricas detalladas
    notas_totales_tocadas INTEGER DEFAULT 0 CHECK (notas_totales_tocadas >= 0),
    notas_correctas INTEGER DEFAULT 0 CHECK (notas_correctas >= 0),
    notas_incorrectas INTEGER DEFAULT 0 CHECK (notas_incorrectas >= 0),
    racha_maxima_notas INTEGER DEFAULT 0 CHECK (racha_maxima_notas >= 0),
    
    -- Timing y precisión
    promedio_timing_ms NUMERIC(8,2) DEFAULT 0,
    errores_timing INTEGER DEFAULT 0 CHECK (errores_timing >= 0),
    cambios_fuelle_correctos INTEGER DEFAULT 0 CHECK (cambios_fuelle_correctos >= 0),
    
    -- Progreso por secciones
    progreso_secciones JSONB DEFAULT '{}',
    /* Estructura JSON:
    {
        "intro": {"completado": true, "precision": 95.5},
        "verso": {"completado": false, "precision": 78.2},
        "coro": {"completado": false, "precision": 0}
    }
    */
    
    -- Recompensas obtenidas
    xp_ganado INTEGER DEFAULT 0 CHECK (xp_ganado >= 0),
    monedas_ganadas INTEGER DEFAULT 0 CHECK (monedas_ganadas >= 0),
    logros_desbloqueados TEXT[] DEFAULT '{}',
    
    -- Fechas importantes
    fecha_inicio TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_ultimo_intento TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_completado TIMESTAMP WITH TIME ZONE,
    fecha_perfecto TIMESTAMP WITH TIME ZONE,
    
    -- Metadatos
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints únicos
    UNIQUE(usuario_id, cancion_id)
);

-- Comentarios de tabla
COMMENT ON TABLE progreso_canciones_acordeon IS '📈 Progreso de usuarios en canciones específicas';
COMMENT ON COLUMN progreso_canciones_acordeon.progreso_secciones IS 'Progreso JSON por secciones de la canción';
COMMENT ON COLUMN progreso_canciones_acordeon.logros_desbloqueados IS 'Array de IDs de logros conseguidos';

-- =====================================================
-- 🎮 TABLA: sesiones_canciones_acordeon
-- =====================================================
-- Tracking detallado de sesiones de práctica
-- Integración con sesiones_simulador_acordeon existente
-- =====================================================

CREATE TABLE IF NOT EXISTS sesiones_canciones_acordeon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
    cancion_id UUID NOT NULL REFERENCES canciones_simulador_acordeon(id) ON DELETE CASCADE,
    
    -- Información de la sesión
    duracion_segundos INTEGER NOT NULL CHECK (duracion_segundos > 0),
    modo_practica TEXT DEFAULT 'completa' CHECK (modo_practica IN ('completa', 'por_secciones', 'solo_dificil')),
    
    -- Métricas de la sesión
    notas_tocadas INTEGER DEFAULT 0 CHECK (notas_tocadas >= 0),
    notas_correctas INTEGER DEFAULT 0 CHECK (notas_correctas >= 0),
    precision_promedio NUMERIC(5,2) DEFAULT 0 CHECK (precision_promedio >= 0 AND precision_promedio <= 100),
    
    -- Timing y ritmo
    errores_timing INTEGER DEFAULT 0 CHECK (errores_timing >= 0),
    cambios_fuelle INTEGER DEFAULT 0 CHECK (cambios_fuelle >= 0),
    tempo_promedio INTEGER DEFAULT 0 CHECK (tempo_promedio >= 0),
    
    -- Estado de la sesión
    completado BOOLEAN DEFAULT FALSE,
    abandono_temprano BOOLEAN DEFAULT FALSE,
    razon_abandono TEXT,
    
    -- Datos específicos de la sesión
    datos_sesion JSONB DEFAULT '{}',
    /* Estructura JSON:
    {
        "secciones_practicadas": ["intro", "verso"],
        "errores_por_seccion": {"intro": 2, "verso": 5},
        "tiempo_por_seccion": {"intro": 30, "verso": 45},
        "notas_problematicas": ["Do#", "Fa"],
        "configuracion_usada": {"tolerancia_ms": 150, "metronomo": true}
    }
    */
    
    -- Gamificación
    xp_ganado INTEGER DEFAULT 0 CHECK (xp_ganado >= 0),
    monedas_ganadas INTEGER DEFAULT 0 CHECK (monedas_ganadas >= 0),
    
    -- Metadatos
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comentarios de tabla
COMMENT ON TABLE sesiones_canciones_acordeon IS '🎮 Tracking detallado de sesiones de práctica de canciones';
COMMENT ON COLUMN sesiones_canciones_acordeon.datos_sesion IS 'Datos específicos JSON de la sesión';
COMMENT ON COLUMN sesiones_canciones_acordeon.modo_practica IS 'Modo de práctica: completa, por_secciones, solo_dificil';

-- =====================================================
-- 📊 ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

-- Índices para canciones
CREATE INDEX IF NOT EXISTS idx_canciones_nivel_dificultad ON canciones_simulador_acordeon(nivel_dificultad);
CREATE INDEX IF NOT EXISTS idx_canciones_genero ON canciones_simulador_acordeon(genero);
CREATE INDEX IF NOT EXISTS idx_canciones_estado ON canciones_simulador_acordeon(estado) WHERE estado = 'activa';
CREATE INDEX IF NOT EXISTS idx_canciones_creador ON canciones_simulador_acordeon(creador_id);
CREATE INDEX IF NOT EXISTS idx_canciones_publica ON canciones_simulador_acordeon(es_publica) WHERE es_publica = TRUE;

-- Índices para secuencias
CREATE INDEX IF NOT EXISTS idx_secuencias_cancion ON secuencias_canciones_acordeon(cancion_id);
CREATE INDEX IF NOT EXISTS idx_secuencias_principal ON secuencias_canciones_acordeon(cancion_id) WHERE es_secuencia_principal = TRUE;

-- Índices para progreso
CREATE INDEX IF NOT EXISTS idx_progreso_usuario ON progreso_canciones_acordeon(usuario_id);
CREATE INDEX IF NOT EXISTS idx_progreso_cancion ON progreso_canciones_acordeon(cancion_id);
CREATE INDEX IF NOT EXISTS idx_progreso_estado ON progreso_canciones_acordeon(estado);
CREATE INDEX IF NOT EXISTS idx_progreso_precision ON progreso_canciones_acordeon(mejor_precision DESC);

-- Índices para sesiones
CREATE INDEX IF NOT EXISTS idx_sesiones_usuario_fecha ON sesiones_canciones_acordeon(usuario_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sesiones_cancion ON sesiones_canciones_acordeon(cancion_id);
CREATE INDEX IF NOT EXISTS idx_sesiones_precision ON sesiones_canciones_acordeon(precision_promedio DESC);

-- =====================================================
-- 🔄 TRIGGERS PARA UPDATED_AT
-- =====================================================

-- Trigger para canciones
CREATE TRIGGER trigger_canciones_acordeon_updated_at
    BEFORE UPDATE ON canciones_simulador_acordeon
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- Trigger para secuencias
CREATE TRIGGER trigger_secuencias_acordeon_updated_at
    BEFORE UPDATE ON secuencias_canciones_acordeon
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- Trigger para progreso
CREATE TRIGGER trigger_progreso_canciones_updated_at
    BEFORE UPDATE ON progreso_canciones_acordeon
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- Trigger para sesiones
CREATE TRIGGER trigger_sesiones_canciones_updated_at
    BEFORE UPDATE ON sesiones_canciones_acordeon
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- =====================================================
-- 🎯 FUNCIONES AUXILIARES
-- =====================================================

-- Función para calcular estadísticas de canción
CREATE OR REPLACE FUNCTION calcular_estadisticas_cancion(p_cancion_id UUID)
RETURNS JSONB AS $$
DECLARE
    estadisticas JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_usuarios', COUNT(DISTINCT usuario_id),
        'usuarios_completaron', COUNT(DISTINCT usuario_id) FILTER (WHERE estado = 'completado'),
        'precision_promedio', ROUND(AVG(mejor_precision), 2),
        'intentos_promedio', ROUND(AVG(intentos_realizados), 1),
        'tiempo_promedio_minutos', ROUND(AVG(tiempo_practicado_minutos), 1)
    )
    INTO estadisticas
    FROM progreso_canciones_acordeon
    WHERE cancion_id = p_cancion_id;
    
    RETURN estadisticas;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener canciones recomendadas
CREATE OR REPLACE FUNCTION obtener_canciones_recomendadas(p_usuario_id UUID, p_limite INTEGER DEFAULT 5)
RETURNS TABLE (
    cancion_id UUID,
    titulo VARCHAR(200),
    artista VARCHAR(200),
    nivel_dificultad INTEGER,
    razon_recomendacion TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH usuario_nivel AS (
        SELECT COALESCE(nivel, 1) as nivel_usuario
        FROM experiencia_usuario
        WHERE usuario_id = p_usuario_id
    ),
    canciones_completadas AS (
        SELECT cancion_id
        FROM progreso_canciones_acordeon
        WHERE usuario_id = p_usuario_id AND estado = 'completado'
    )
    SELECT 
        c.id,
        c.titulo,
        c.artista,
        c.nivel_dificultad,
        CASE 
            WHEN c.nivel_dificultad <= (SELECT nivel_usuario FROM usuario_nivel) THEN 'Nivel adecuado'
            WHEN c.nivel_dificultad = (SELECT nivel_usuario FROM usuario_nivel) + 1 THEN 'Desafío moderado'
            ELSE 'Desafío avanzado'
        END as razon_recomendacion
    FROM canciones_simulador_acordeon c
    WHERE c.estado = 'activa' 
        AND c.es_publica = TRUE
        AND c.id NOT IN (SELECT cancion_id FROM canciones_completadas)
    ORDER BY 
        ABS(c.nivel_dificultad - (SELECT nivel_usuario FROM usuario_nivel)),
        c.orden_mostrar,
        c.created_at DESC
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 🎉 MENSAJE DE FINALIZACIÓN
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🎵 ¡Sistema de Canciones para Simulador de Acordeón creado exitosamente!';
    RAISE NOTICE '📊 Tablas creadas:';
    RAISE NOTICE '   - canciones_simulador_acordeon';
    RAISE NOTICE '   - secuencias_canciones_acordeon';
    RAISE NOTICE '   - progreso_canciones_acordeon';
    RAISE NOTICE '   - sesiones_canciones_acordeon';
    RAISE NOTICE '🚀 Funciones auxiliares creadas:';
    RAISE NOTICE '   - calcular_estadisticas_cancion()';
    RAISE NOTICE '   - obtener_canciones_recomendadas()';
    RAISE NOTICE '✅ ¡Listo para crear canciones estilo Guitar Hero!';
END $$; 