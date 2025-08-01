-- =====================================================
-- SCRIPT: TABLA DE GEOLOCALIZACIÓN DE USUARIOS
-- Descripción: Almacena datos de IP y ubicación geográfica
-- Fecha: Diciembre 2024
-- =====================================================

-- 1. CREAR TABLA PRINCIPAL
CREATE TABLE IF NOT EXISTS public.geolocalizacion_usuarios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    
    -- DATOS DE IP Y CONEXIÓN
    ip INET NOT NULL,
    isp TEXT,
    organizacion TEXT,
    tipo_conexion TEXT CHECK (tipo_conexion IN ('Móvil', 'Fija', 'Desconocido')),
    es_movil BOOLEAN DEFAULT FALSE,
    es_proxy BOOLEAN DEFAULT FALSE,
    es_vpn BOOLEAN DEFAULT FALSE,
    
    -- DATOS GEOGRÁFICOS
    pais TEXT NOT NULL,
    pais_codigo TEXT NOT NULL, -- Código de 2 letras (ISO 3166-1 alpha-2)
    region TEXT,
    ciudad TEXT,
    latitud DECIMAL(10, 8),
    longitud DECIMAL(11, 8),
    zona_horaria TEXT,
    
    -- DATOS ADICIONALES
    moneda TEXT DEFAULT 'USD',
    idioma TEXT DEFAULT 'es',
    bandera_url TEXT,
    
    -- METADATOS DE SEGUIMIENTO
    primera_visita TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ultima_visita TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    visitas_totales INTEGER DEFAULT 1,
    
    -- TIMESTAMPS AUTOMÁTICOS
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- ÍNDICE ÚNICO POR USUARIO E IP (evita duplicados)
    UNIQUE(usuario_id, ip)
);

-- 2. CREAR ÍNDICES PARA MEJORAR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_geolocalizacion_usuario_id ON public.geolocalizacion_usuarios(usuario_id);
CREATE INDEX IF NOT EXISTS idx_geolocalizacion_ip ON public.geolocalizacion_usuarios(ip);
CREATE INDEX IF NOT EXISTS idx_geolocalizacion_pais ON public.geolocalizacion_usuarios(pais);
CREATE INDEX IF NOT EXISTS idx_geolocalizacion_ciudad ON public.geolocalizacion_usuarios(ciudad);
CREATE INDEX IF NOT EXISTS idx_geolocalizacion_ultima_visita ON public.geolocalizacion_usuarios(ultima_visita);
CREATE INDEX IF NOT EXISTS idx_geolocalizacion_es_movil ON public.geolocalizacion_usuarios(es_movil);
CREATE INDEX IF NOT EXISTS idx_geolocalizacion_es_vpn ON public.geolocalizacion_usuarios(es_vpn);

-- 3. CREAR TRIGGER PARA ACTUALIZAR updated_at AUTOMÁTICAMENTE
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_geolocalizacion_updated_at 
    BEFORE UPDATE ON public.geolocalizacion_usuarios 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 4. FUNCIÓN PARA INCREMENTAR VISITAS
CREATE OR REPLACE FUNCTION increment_visitas(registro_id UUID)
RETURNS INTEGER AS $$
DECLARE
    nuevo_total INTEGER;
BEGIN
    UPDATE public.geolocalizacion_usuarios 
    SET visitas_totales = visitas_totales + 1,
        ultima_visita = NOW(),
        updated_at = NOW()
    WHERE id = registro_id
    RETURNING visitas_totales INTO nuevo_total;
    
    RETURN COALESCE(nuevo_total, 0);
END;
$$ LANGUAGE plpgsql;

-- 5. VISTA PARA ESTADÍSTICAS GEOGRÁFICAS
CREATE OR REPLACE VIEW public.vista_estadisticas_geograficas AS
SELECT 
    -- Conteos generales
    COUNT(DISTINCT usuario_id) as total_usuarios,
    COUNT(DISTINCT pais) as paises_unicos,
    COUNT(DISTINCT ciudad) as ciudades_unicas,
    COUNT(DISTINCT ip) as ips_unicas,
    
    -- Tipos de conexión
    COUNT(*) FILTER (WHERE es_movil = true) as usuarios_moviles,
    COUNT(*) FILTER (WHERE es_vpn = true) as usuarios_vpn,
    COUNT(*) FILTER (WHERE es_proxy = true) as usuarios_proxy,
    
    -- Totales de actividad
    SUM(visitas_totales) as total_visitas,
    AVG(visitas_totales) as promedio_visitas_por_usuario,
    
    -- Fechas de actividad
    MIN(primera_visita) as primera_visita_global,
    MAX(ultima_visita) as ultima_visita_global,
    
    -- Distribución geográfica
    COUNT(*) FILTER (WHERE pais = 'Colombia') as usuarios_colombia,
    COUNT(*) FILTER (WHERE pais != 'Colombia') as usuarios_internacionales,
    
    -- Porcentajes
    ROUND(
        (COUNT(*) FILTER (WHERE es_movil = true)::DECIMAL / COUNT(*)) * 100, 2
    ) as porcentaje_moviles,
    
    ROUND(
        (COUNT(*) FILTER (WHERE es_vpn = true)::DECIMAL / COUNT(*)) * 100, 2
    ) as porcentaje_vpn
    
FROM public.geolocalizacion_usuarios;

-- 6. VISTA PARA TOP PAÍSES
CREATE OR REPLACE VIEW public.vista_top_paises AS
SELECT 
    pais,
    pais_codigo,
    COUNT(DISTINCT usuario_id) as usuarios_unicos,
    COUNT(*) as total_registros,
    SUM(visitas_totales) as total_visitas,
    AVG(visitas_totales) as promedio_visitas,
    MAX(ultima_visita) as ultima_actividad,
    
    -- Porcentaje del total
    ROUND(
        (COUNT(DISTINCT usuario_id)::DECIMAL / 
         (SELECT COUNT(DISTINCT usuario_id) FROM public.geolocalizacion_usuarios)) * 100, 
        2
    ) as porcentaje_usuarios
    
FROM public.geolocalizacion_usuarios
GROUP BY pais, pais_codigo
ORDER BY usuarios_unicos DESC, total_visitas DESC;

-- 7. VISTA PARA TOP CIUDADES
CREATE OR REPLACE VIEW public.vista_top_ciudades AS
SELECT 
    ciudad,
    pais,
    pais_codigo,
    COUNT(DISTINCT usuario_id) as usuarios_unicos,
    COUNT(*) as total_registros,
    SUM(visitas_totales) as total_visitas,
    MAX(ultima_visita) as ultima_actividad
    
FROM public.geolocalizacion_usuarios
GROUP BY ciudad, pais, pais_codigo
ORDER BY usuarios_unicos DESC, total_visitas DESC;

-- 8. FUNCIÓN PARA OBTENER UBICACIONES RECIENTES
CREATE OR REPLACE FUNCTION obtener_ubicaciones_recientes(limite INTEGER DEFAULT 20)
RETURNS TABLE (
    usuario_id UUID,
    usuario_nombre TEXT,
    ip INET,
    pais TEXT,
    ciudad TEXT,
    bandera_url TEXT,
    es_movil BOOLEAN,
    es_vpn BOOLEAN,
    ultima_visita TIMESTAMPTZ,
    visitas_totales INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.usuario_id,
        CONCAT(p.nombre, ' ', p.apellido) as usuario_nombre,
        g.ip,
        g.pais,
        g.ciudad,
        g.bandera_url,
        g.es_movil,
        g.es_vpn,
        g.ultima_visita,
        g.visitas_totales
    FROM public.geolocalizacion_usuarios g
    JOIN public.perfiles p ON g.usuario_id = p.id
    WHERE p.eliminado = false
    ORDER BY g.ultima_visita DESC
    LIMIT limite;
END;
$$ LANGUAGE plpgsql;

-- 9. FUNCIÓN PARA OBTENER HISTORIAL DE UN USUARIO
CREATE OR REPLACE FUNCTION obtener_historial_usuario_geo(user_id UUID)
RETURNS TABLE (
    id UUID,
    ip INET,
    pais TEXT,
    ciudad TEXT,
    isp TEXT,
    tipo_conexion TEXT,
    es_movil BOOLEAN,
    es_vpn BOOLEAN,
    primera_visita TIMESTAMPTZ,
    ultima_visita TIMESTAMPTZ,
    visitas_totales INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.id,
        g.ip,
        g.pais,
        g.ciudad,
        g.isp,
        g.tipo_conexion,
        g.es_movil,
        g.es_vpn,
        g.primera_visita,
        g.ultima_visita,
        g.visitas_totales
    FROM public.geolocalizacion_usuarios g
    WHERE g.usuario_id = user_id
    ORDER BY g.ultima_visita DESC;
END;
$$ LANGUAGE plpgsql;

-- 10. POLÍTICAS RLS (Row Level Security)
ALTER TABLE public.geolocalizacion_usuarios ENABLE ROW LEVEL SECURITY;

-- Política para que los administradores puedan ver todo
CREATE POLICY "Administradores pueden ver todo" ON public.geolocalizacion_usuarios
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.perfiles 
            WHERE id = auth.uid() 
            AND rol = 'administrador'
        )
    );

-- Política para que los usuarios solo vean sus propios datos
CREATE POLICY "Usuarios ven sus propios datos" ON public.geolocalizacion_usuarios
    FOR SELECT USING (usuario_id = auth.uid());

-- 11. INSERTAR DATOS DE EJEMPLO (OPCIONAL)
INSERT INTO public.geolocalizacion_usuarios (
    usuario_id, ip, pais, pais_codigo, region, ciudad, 
    latitud, longitud, zona_horaria, isp, organizacion,
    tipo_conexion, es_movil, es_vpn, moneda, idioma, bandera_url
) VALUES 
    -- Estos son datos de ejemplo, se reemplazarán con datos reales
    (
        (SELECT id FROM public.perfiles WHERE rol = 'estudiante' LIMIT 1),
        '190.144.200.123',
        'Colombia',
        'CO',
        'Cesar',
        'Valledupar',
        10.4631,
        -73.2532,
        'America/Bogota',
        'Tigo Colombia',
        'Colombia Telecomunicaciones S.A.',
        'Móvil',
        true,
        false,
        'COP',
        'es',
        'https://flagcdn.com/32x24/co.png'
    )
ON CONFLICT (usuario_id, ip) DO NOTHING;

-- 12. COMENTARIOS DE DOCUMENTACIÓN
COMMENT ON TABLE public.geolocalizacion_usuarios IS 'Almacena datos de geolocalización e IP de usuarios para analytics y seguridad';
COMMENT ON COLUMN public.geolocalizacion_usuarios.ip IS 'Dirección IP del usuario (IPv4 o IPv6)';
COMMENT ON COLUMN public.geolocalizacion_usuarios.es_vpn IS 'Indica si la IP corresponde a un VPN o proxy';
COMMENT ON COLUMN public.geolocalizacion_usuarios.visitas_totales IS 'Número total de visitas desde esta IP';
COMMENT ON COLUMN public.geolocalizacion_usuarios.zona_horaria IS 'Zona horaria del usuario según su ubicación';

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================

-- INSTRUCCIONES DE USO:
-- 1. Ejecutar este script completo en Supabase SQL Editor
-- 2. Verificar que todas las tablas y funciones se crearon correctamente
-- 3. El sistema automáticamente empezará a recopilar datos de geolocalización
-- 4. Usar las vistas para obtener estadísticas rápidas
-- 5. Usar las funciones para consultas específicas

-- EJEMPLO DE CONSULTAS:
-- SELECT * FROM vista_estadisticas_geograficas;
-- SELECT * FROM vista_top_paises LIMIT 10;
-- SELECT * FROM obtener_ubicaciones_recientes(50);
-- SELECT * FROM obtener_historial_usuario_geo('USER_ID_AQUI'); 