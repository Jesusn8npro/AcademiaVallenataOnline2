-- ============================================
-- SISTEMA DE EVENTOS - ACADEMIA VALLENATA ONLINE
-- ============================================

-- 1. TABLA PRINCIPAL DE EVENTOS
CREATE TABLE IF NOT EXISTS eventos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT,
    descripcion_corta VARCHAR(500),
    slug VARCHAR(255) UNIQUE NOT NULL,
    tipo_evento VARCHAR(50) NOT NULL DEFAULT 'masterclass', 
    -- 'masterclass', 'workshop', 'concierto', 'concurso', 'webinar', 'reunion'
    
    -- FECHAS Y HORARIOS
    fecha_inicio TIMESTAMP WITH TIME ZONE NOT NULL,
    fecha_fin TIMESTAMP WITH TIME ZONE,
    es_todo_el_dia BOOLEAN DEFAULT false,
    zona_horaria VARCHAR(50) DEFAULT 'America/Bogota',
    
    -- UBICACIÓN Y ACCESO
    modalidad VARCHAR(20) DEFAULT 'online', -- 'online', 'presencial', 'hibrido'
    ubicacion_fisica TEXT, -- Dirección física si es presencial
    link_transmision VARCHAR(500), -- URL para Zoom, Meet, etc.
    enlace_grabacion VARCHAR(500), -- URL del video grabado
    codigo_acceso VARCHAR(100), -- Código de acceso para la transmisión
    
    -- INSTRUCTOR Y ORGANIZACIÓN
    instructor_id UUID REFERENCES perfiles(id),
    instructor_nombre VARCHAR(255), -- Cache del nombre para mejor rendimiento
    instructor_avatar VARCHAR(500), -- Cache del avatar
    
    -- CAPACIDAD Y PRECIOS
    capacidad_maxima INTEGER DEFAULT 100,
    participantes_inscritos INTEGER DEFAULT 0,
    precio NUMERIC(10,2) DEFAULT 0,
    precio_rebajado NUMERIC(10,2),
    moneda VARCHAR(3) DEFAULT 'COP',
    es_gratuito BOOLEAN GENERATED ALWAYS AS (precio = 0) STORED,
    
    -- CONTENIDO MULTIMEDIA
    imagen_portada VARCHAR(500),
    imagen_banner VARCHAR(500),
    video_promocional VARCHAR(500),
    
    -- CATEGORIZACIÓN
    categoria VARCHAR(50), -- 'tecnica', 'teoria', 'repertorio', 'historia'
    nivel_dificultad VARCHAR(20), -- 'principiante', 'intermedio', 'avanzado', 'profesional'
    tags TEXT[], -- Array de etiquetas
    
    -- CONFIGURACIÓN
    requiere_inscripcion BOOLEAN DEFAULT true,
    acepta_invitados BOOLEAN DEFAULT false,
    es_publico BOOLEAN DEFAULT true,
    es_destacado BOOLEAN DEFAULT false,
    permite_grabacion BOOLEAN DEFAULT true,
    
    -- ESTADO
    estado VARCHAR(20) DEFAULT 'programado', 
    -- 'borrador', 'programado', 'en_vivo', 'finalizado', 'cancelado', 'pospuesto'
    
    -- METADATA
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    creado_por UUID REFERENCES perfiles(id),
    fecha_publicacion TIMESTAMP WITH TIME ZONE,
    
    -- ESTADÍSTICAS
    total_visualizaciones INTEGER DEFAULT 0,
    calificacion_promedio NUMERIC(2,1) DEFAULT 0,
    total_calificaciones INTEGER DEFAULT 0
);

-- 2. TABLA DE INSCRIPCIONES A EVENTOS
CREATE TABLE IF NOT EXISTS eventos_inscripciones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    evento_id UUID REFERENCES eventos(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
    
    -- INFORMACIÓN DE INSCRIPCIÓN
    fecha_inscripcion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estado_inscripcion VARCHAR(20) DEFAULT 'confirmado',
    -- 'pendiente', 'confirmado', 'cancelado', 'asistio', 'no_asistio'
    
    -- PAGO (si el evento es pago)
    pago_id UUID REFERENCES pagos_epayco(id),
    monto_pagado NUMERIC(10,2),
    fecha_pago TIMESTAMP WITH TIME ZONE,
    
    -- PARTICIPACIÓN
    fecha_ultima_conexion TIMESTAMP WITH TIME ZONE,
    tiempo_total_conectado INTEGER DEFAULT 0, -- en minutos
    
    -- CALIFICACIÓN DEL EVENTO
    calificacion INTEGER CHECK (calificacion >= 1 AND calificacion <= 5),
    comentario_calificacion TEXT,
    fecha_calificacion TIMESTAMP WITH TIME ZONE,
    
    -- METADATA
    notas_usuario TEXT,
    notificaciones_habilitadas BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- CONSTRAINTS
    UNIQUE(evento_id, usuario_id)
);

-- 3. TABLA DE RECORDATORIOS
CREATE TABLE IF NOT EXISTS eventos_recordatorios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    evento_id UUID REFERENCES eventos(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
    
    -- CONFIGURACIÓN DEL RECORDATORIO
    tipo_recordatorio VARCHAR(20) NOT NULL, -- 'email', 'push', 'sms'
    minutos_antes INTEGER NOT NULL, -- 15, 60, 1440 (24h), 2880 (48h)
    
    -- ESTADO
    programado BOOLEAN DEFAULT true,
    enviado BOOLEAN DEFAULT false,
    fecha_programada TIMESTAMP WITH TIME ZONE,
    fecha_envio TIMESTAMP WITH TIME ZONE,
    
    -- MENSAJE PERSONALIZADO
    mensaje_personalizado TEXT,
    
    -- METADATA
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- CONSTRAINTS
    UNIQUE(evento_id, usuario_id, tipo_recordatorio, minutos_antes)
);

-- 4. TABLA DE SESIONES EN VIVO (para eventos que requieren seguimiento)
CREATE TABLE IF NOT EXISTS eventos_sesiones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    evento_id UUID REFERENCES eventos(id) ON DELETE CASCADE,
    
    -- INFORMACIÓN DE LA SESIÓN
    numero_sesion INTEGER DEFAULT 1,
    titulo_sesion VARCHAR(255),
    descripcion_sesion TEXT,
    
    -- HORARIOS
    hora_inicio TIMESTAMP WITH TIME ZONE,
    hora_fin TIMESTAMP WITH TIME ZONE,
    duracion_minutos INTEGER,
    
    -- STREAMING
    link_streaming VARCHAR(500),
    link_grabacion VARCHAR(500),
    esta_activa BOOLEAN DEFAULT false,
    
    -- ESTADÍSTICAS
    asistentes_pico INTEGER DEFAULT 0,
    total_reproducciones INTEGER DEFAULT 0,
    
    -- METADATA
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TABLA DE MATERIALES DEL EVENTO
CREATE TABLE IF NOT EXISTS eventos_materiales (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    evento_id UUID REFERENCES eventos(id) ON DELETE CASCADE,
    
    -- INFORMACIÓN DEL MATERIAL
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT,
    tipo_material VARCHAR(50), -- 'pdf', 'video', 'audio', 'imagen', 'enlace', 'partitura'
    
    -- ARCHIVO
    url_archivo VARCHAR(500),
    nombre_archivo VARCHAR(255),
    tamano_archivo BIGINT, -- en bytes
    
    -- ACCESO
    es_publico BOOLEAN DEFAULT false,
    requiere_inscripcion BOOLEAN DEFAULT true,
    disponible_antes_evento BOOLEAN DEFAULT false,
    disponible_despues_evento BOOLEAN DEFAULT true,
    
    -- METADATA
    orden_visualizacion INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    subido_por UUID REFERENCES perfiles(id)
);

-- 6. TABLA DE COMENTARIOS Y PREGUNTAS EN VIVO
CREATE TABLE IF NOT EXISTS eventos_comentarios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    evento_id UUID REFERENCES eventos(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
    
    -- CONTENIDO
    mensaje TEXT NOT NULL,
    tipo_mensaje VARCHAR(20) DEFAULT 'comentario', -- 'comentario', 'pregunta', 'respuesta'
    mensaje_padre_id UUID REFERENCES eventos_comentarios(id), -- para respuestas
    
    -- MODERACIÓN
    es_destacado BOOLEAN DEFAULT false,
    es_aprobado BOOLEAN DEFAULT true,
    moderado_por UUID REFERENCES perfiles(id),
    
    -- TIMESTAMP DEL STREAM (para eventos en vivo)
    minuto_stream INTEGER, -- en qué minuto del stream se hizo el comentario
    
    -- METADATA
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ÍNDICES PARA OPTIMIZAR RENDIMIENTO
-- ============================================

-- Índices para eventos
CREATE INDEX IF NOT EXISTS idx_eventos_fecha_inicio ON eventos(fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_eventos_estado ON eventos(estado);
CREATE INDEX IF NOT EXISTS idx_eventos_tipo ON eventos(tipo_evento);
CREATE INDEX IF NOT EXISTS idx_eventos_instructor ON eventos(instructor_id);
CREATE INDEX IF NOT EXISTS idx_eventos_categoria ON eventos(categoria);
CREATE INDEX IF NOT EXISTS idx_eventos_nivel ON eventos(nivel_dificultad);
CREATE INDEX IF NOT EXISTS idx_eventos_publicos ON eventos(es_publico) WHERE es_publico = true;
CREATE INDEX IF NOT EXISTS idx_eventos_gratuitos ON eventos(es_gratuito) WHERE es_gratuito = true;

-- Índices para inscripciones
CREATE INDEX IF NOT EXISTS idx_inscripciones_usuario ON eventos_inscripciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_inscripciones_evento ON eventos_inscripciones(evento_id);
CREATE INDEX IF NOT EXISTS idx_inscripciones_estado ON eventos_inscripciones(estado_inscripcion);

-- Índices para recordatorios
CREATE INDEX IF NOT EXISTS idx_recordatorios_programados ON eventos_recordatorios(fecha_programada) WHERE programado = true AND enviado = false;

-- ============================================
-- TRIGGERS AUTOMÁTICOS
-- ============================================

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar triggers
CREATE TRIGGER trigger_eventos_updated_at
    BEFORE UPDATE ON eventos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

CREATE TRIGGER trigger_inscripciones_updated_at
    BEFORE UPDATE ON eventos_inscripciones
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- Trigger para actualizar contador de participantes
CREATE OR REPLACE FUNCTION actualizar_contador_participantes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.estado_inscripcion = 'confirmado' THEN
        UPDATE eventos 
        SET participantes_inscritos = participantes_inscritos + 1
        WHERE id = NEW.evento_id;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.estado_inscripcion != 'confirmado' AND NEW.estado_inscripcion = 'confirmado' THEN
            UPDATE eventos 
            SET participantes_inscritos = participantes_inscritos + 1
            WHERE id = NEW.evento_id;
        ELSIF OLD.estado_inscripcion = 'confirmado' AND NEW.estado_inscripcion != 'confirmado' THEN
            UPDATE eventos 
            SET participantes_inscritos = participantes_inscritos - 1
            WHERE id = NEW.evento_id;
        END IF;
    ELSIF TG_OP = 'DELETE' AND OLD.estado_inscripcion = 'confirmado' THEN
        UPDATE eventos 
        SET participantes_inscritos = participantes_inscritos - 1
        WHERE id = OLD.evento_id;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_participantes
    AFTER INSERT OR UPDATE OR DELETE ON eventos_inscripciones
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_contador_participantes();

-- Trigger para actualizar calificación promedio
CREATE OR REPLACE FUNCTION actualizar_calificacion_evento()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE eventos 
    SET 
        calificacion_promedio = (
            SELECT COALESCE(AVG(calificacion::NUMERIC), 0)
            FROM eventos_inscripciones 
            WHERE evento_id = COALESCE(NEW.evento_id, OLD.evento_id) 
            AND calificacion IS NOT NULL
        ),
        total_calificaciones = (
            SELECT COUNT(*)
            FROM eventos_inscripciones 
            WHERE evento_id = COALESCE(NEW.evento_id, OLD.evento_id) 
            AND calificacion IS NOT NULL
        )
    WHERE id = COALESCE(NEW.evento_id, OLD.evento_id);
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_calificacion
    AFTER INSERT OR UPDATE OR DELETE ON eventos_inscripciones
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_calificacion_evento();

-- ============================================
-- POLÍTICAS RLS (SEGURIDAD)
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE eventos ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos_inscripciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos_recordatorios ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos_sesiones ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos_materiales ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos_comentarios ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS PARA EVENTOS

-- Ver eventos: todos pueden ver eventos públicos, usuarios autenticados pueden ver sus propios eventos
CREATE POLICY "eventos_select_policy" ON eventos
    FOR SELECT USING (
        es_publico = true 
        OR estado = 'programado' 
        OR auth.uid() IS NOT NULL
    );

-- Crear eventos: solo admins e instructores
CREATE POLICY "eventos_insert_policy" ON eventos
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol IN ('admin', 'instructor')
        )
    );

-- Actualizar eventos: solo el creador, instructor asignado o admin
CREATE POLICY "eventos_update_policy" ON eventos
    FOR UPDATE USING (
        creado_por = auth.uid()
        OR instructor_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol = 'admin'
        )
    );

-- Eliminar eventos: solo admin o creador
CREATE POLICY "eventos_delete_policy" ON eventos
    FOR DELETE USING (
        creado_por = auth.uid()
        OR EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol = 'admin'
        )
    );

-- POLÍTICAS PARA INSCRIPCIONES

-- Ver inscripciones: solo el usuario o admin
CREATE POLICY "inscripciones_select_policy" ON eventos_inscripciones
    FOR SELECT USING (
        usuario_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol = 'admin'
        )
        OR EXISTS (
            SELECT 1 FROM eventos e
            WHERE e.id = evento_id 
            AND e.instructor_id = auth.uid()
        )
    );

-- Crear inscripciones: usuarios autenticados
CREATE POLICY "inscripciones_insert_policy" ON eventos_inscripciones
    FOR INSERT WITH CHECK (
        usuario_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol = 'admin'
        )
    );

-- Actualizar inscripciones: solo el usuario o admin
CREATE POLICY "inscripciones_update_policy" ON eventos_inscripciones
    FOR UPDATE USING (
        usuario_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol = 'admin'
        )
    );

-- POLÍTICAS PARA RECORDATORIOS

-- Recordatorios: solo el usuario propietario
CREATE POLICY "recordatorios_policy" ON eventos_recordatorios
    FOR ALL USING (usuario_id = auth.uid());

-- POLÍTICAS PARA SESIONES

-- Ver sesiones: usuarios que pueden ver el evento
CREATE POLICY "sesiones_select_policy" ON eventos_sesiones
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM eventos e
            WHERE e.id = evento_id
            AND (
                e.es_publico = true
                OR EXISTS (
                    SELECT 1 FROM eventos_inscripciones ei
                    WHERE ei.evento_id = e.id 
                    AND ei.usuario_id = auth.uid()
                    AND ei.estado_inscripcion = 'confirmado'
                )
            )
        )
    );

-- Crear/actualizar sesiones: instructor del evento o admin
CREATE POLICY "sesiones_modify_policy" ON eventos_sesiones
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM eventos e
            WHERE e.id = evento_id
            AND (
                e.instructor_id = auth.uid()
                OR e.creado_por = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM perfiles p
                    WHERE p.id = auth.uid() AND p.rol = 'admin'
                )
            )
        )
    );

-- POLÍTICAS PARA MATERIALES

-- Ver materiales: según configuración del material y acceso al evento
CREATE POLICY "materiales_select_policy" ON eventos_materiales
    FOR SELECT USING (
        es_publico = true
        OR EXISTS (
            SELECT 1 FROM eventos_inscripciones ei
            JOIN eventos e ON e.id = ei.evento_id
            WHERE ei.evento_id = evento_id
            AND ei.usuario_id = auth.uid()
            AND ei.estado_inscripcion = 'confirmado'
            AND (
                (requiere_inscripcion = false)
                OR (disponible_antes_evento = true AND e.fecha_inicio > NOW())
                OR (e.fecha_inicio <= NOW() AND e.fecha_fin >= NOW())
                OR (disponible_despues_evento = true AND e.fecha_fin < NOW())
            )
        )
    );

-- Crear materiales: instructor del evento o admin
CREATE POLICY "materiales_modify_policy" ON eventos_materiales
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM eventos e
            WHERE e.id = evento_id
            AND (
                e.instructor_id = auth.uid()
                OR e.creado_por = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM perfiles p
                    WHERE p.id = auth.uid() AND p.rol = 'admin'
                )
            )
        )
    );

-- POLÍTICAS PARA COMENTARIOS

-- Ver comentarios: usuarios inscritos en el evento
CREATE POLICY "comentarios_select_policy" ON eventos_comentarios
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM eventos_inscripciones ei
            WHERE ei.evento_id = evento_id
            AND ei.usuario_id = auth.uid()
            AND ei.estado_inscripcion = 'confirmado'
        )
        OR EXISTS (
            SELECT 1 FROM eventos e
            WHERE e.id = evento_id
            AND (e.instructor_id = auth.uid() OR e.creado_por = auth.uid())
        )
        OR EXISTS (
            SELECT 1 FROM perfiles p
            WHERE p.id = auth.uid() AND p.rol = 'admin'
        )
    );

-- Crear comentarios: usuarios inscritos
CREATE POLICY "comentarios_insert_policy" ON eventos_comentarios
    FOR INSERT WITH CHECK (
        usuario_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM eventos_inscripciones ei
            WHERE ei.evento_id = evento_id
            AND ei.usuario_id = auth.uid()
            AND ei.estado_inscripcion = 'confirmado'
        )
    );

-- Actualizar comentarios: solo el autor o moderadores
CREATE POLICY "comentarios_update_policy" ON eventos_comentarios
    FOR UPDATE USING (
        usuario_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM eventos e
            WHERE e.id = evento_id
            AND (e.instructor_id = auth.uid() OR e.creado_por = auth.uid())
        )
        OR EXISTS (
            SELECT 1 FROM perfiles p
            WHERE p.id = auth.uid() AND p.rol = 'admin'
        )
    );

-- ============================================
-- FUNCIONES ÚTILES
-- ============================================

-- Función para obtener eventos próximos
CREATE OR REPLACE FUNCTION obtener_eventos_proximos(limite INT DEFAULT 5)
RETURNS TABLE (
    id UUID,
    titulo VARCHAR,
    fecha_inicio TIMESTAMP WITH TIME ZONE,
    tipo_evento VARCHAR,
    instructor_nombre VARCHAR,
    participantes_inscritos INT,
    capacidad_maxima INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.titulo,
        e.fecha_inicio,
        e.tipo_evento,
        e.instructor_nombre,
        e.participantes_inscritos,
        e.capacidad_maxima
    FROM eventos e
    WHERE e.es_publico = true
    AND e.estado = 'programado'
    AND e.fecha_inicio > NOW()
    ORDER BY e.fecha_inicio ASC
    LIMIT limite;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar disponibilidad de inscripción
CREATE OR REPLACE FUNCTION verificar_disponibilidad_evento(evento_uuid UUID, usuario_uuid UUID)
RETURNS JSONB AS $$
DECLARE
    evento_data RECORD;
    ya_inscrito BOOLEAN;
    resultado JSONB;
BEGIN
    -- Obtener datos del evento
    SELECT 
        estado, 
        capacidad_maxima, 
        participantes_inscritos,
        fecha_inicio,
        requiere_inscripcion
    INTO evento_data
    FROM eventos 
    WHERE id = evento_uuid;
    
    -- Verificar si ya está inscrito
    SELECT EXISTS(
        SELECT 1 FROM eventos_inscripciones 
        WHERE evento_id = evento_uuid 
        AND usuario_id = usuario_uuid
        AND estado_inscripcion = 'confirmado'
    ) INTO ya_inscrito;
    
    -- Construir respuesta
    resultado := jsonb_build_object(
        'puede_inscribirse', (
            evento_data.estado = 'programado' 
            AND evento_data.fecha_inicio > NOW()
            AND NOT ya_inscrito
            AND (evento_data.capacidad_maxima IS NULL OR evento_data.participantes_inscritos < evento_data.capacidad_maxima)
            AND evento_data.requiere_inscripcion = true
        ),
        'ya_inscrito', ya_inscrito,
        'evento_lleno', (evento_data.capacidad_maxima IS NOT NULL AND evento_data.participantes_inscritos >= evento_data.capacidad_maxima),
        'evento_iniciado', (evento_data.fecha_inicio <= NOW()),
        'mensaje', CASE
            WHEN ya_inscrito THEN 'Ya estás inscrito en este evento'
            WHEN evento_data.estado != 'programado' THEN 'El evento no está disponible para inscripción'
            WHEN evento_data.fecha_inicio <= NOW() THEN 'El evento ya ha iniciado'
            WHEN evento_data.capacidad_maxima IS NOT NULL AND evento_data.participantes_inscritos >= evento_data.capacidad_maxima THEN 'El evento está lleno'
            WHEN evento_data.requiere_inscripcion = false THEN 'Este evento no requiere inscripción previa'
            ELSE 'Puedes inscribirte en este evento'
        END
    );
    
    RETURN resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- DATOS DE EJEMPLO (OPCIONAL)
-- ============================================

-- Insertar algunos eventos de ejemplo
INSERT INTO eventos (
    titulo, descripcion, descripcion_corta, slug, tipo_evento,
    fecha_inicio, fecha_fin, modalidad, 
    precio, categoria, nivel_dificultad, es_publico, es_destacado,
    instructor_nombre, imagen_portada, creado_por
) VALUES 
(
    'Masterclass: Técnicas Avanzadas de Acordeón',
    'Aprende las técnicas más avanzadas del acordeón vallenato con ejercicios prácticos y consejos profesionales.',
    'Técnicas avanzadas con ejercicios prácticos',
    'masterclass-tecnicas-avanzadas-acordeon',
    'masterclass',
    NOW() + INTERVAL '7 days',
    NOW() + INTERVAL '7 days' + INTERVAL '2 hours',
    'online',
    50000,
    'tecnica',
    'avanzado',
    true,
    true,
    'Jesús González',
    'https://academiavallenataonline.com/wp-content/uploads/2020/04/masterclass-acordeon.jpg',
    (SELECT id FROM perfiles WHERE rol = 'admin' LIMIT 1)
),
(
    'Workshop Gratuito: Primeros Pasos en el Acordeón',
    'Taller introductorio perfecto para quienes quieren comenzar su camino en el acordeón vallenato.',
    'Taller introductorio gratuito para principiantes',
    'workshop-primeros-pasos-acordeon',
    'workshop',
    NOW() + INTERVAL '3 days',
    NOW() + INTERVAL '3 days' + INTERVAL '1.5 hours',
    'online',
    0,
    'tecnica',
    'principiante',
    true,
    false,
    'Jesús González',
    'https://academiavallenataonline.com/wp-content/uploads/2020/04/workshop-principiantes.jpg',
    (SELECT id FROM perfiles WHERE rol = 'admin' LIMIT 1)
);

-- Mensaje de finalización
DO $$
BEGIN
    RAISE NOTICE 'Sistema de eventos creado exitosamente!';
    RAISE NOTICE 'Tablas creadas: eventos, eventos_inscripciones, eventos_recordatorios, eventos_sesiones, eventos_materiales, eventos_comentarios';
    RAISE NOTICE 'Políticas RLS configuradas correctamente';
    RAISE NOTICE 'Triggers y funciones automáticas activadas';
END $$; 