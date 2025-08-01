-- 🌍 FUNCIÓN SQL OPTIMIZADA PARA IPAPI.CO
-- =====================================================
-- Función específicamente diseñada para los campos de ipapi.co
-- Campos disponibles: city, region, country_name, country_code, latitude, longitude, timezone, org, etc.

-- Actualizar función para ipapi.co
CREATE OR REPLACE FUNCTION public.upsert_geolocalizacion_usuario(
    p_usuario_id UUID,
    p_ip TEXT,
    p_datos_geo JSONB
)
RETURNS UUID AS $$
DECLARE
    v_registro_id UUID;
    v_ip_inet INET;
    v_country_name TEXT;
    v_city TEXT;
    v_country_code TEXT;
    v_region TEXT;
    v_latitude DECIMAL;
    v_longitude DECIMAL;
    v_timezone TEXT;
    v_org TEXT;
BEGIN
    -- Convertir IP a INET
    BEGIN
        v_ip_inet := p_ip::INET;
    EXCEPTION WHEN OTHERS THEN
        v_ip_inet := '0.0.0.0'::INET;
    END;

    -- Extraer campos específicos de ipapi.co
    v_country_name := p_datos_geo->>'country_name';
    v_city := p_datos_geo->>'city';
    v_country_code := LOWER(p_datos_geo->>'country_code');
    v_region := p_datos_geo->>'region';
    v_latitude := (p_datos_geo->>'latitude')::DECIMAL;
    v_longitude := (p_datos_geo->>'longitude')::DECIMAL;
    v_timezone := p_datos_geo->>'timezone';
    v_org := p_datos_geo->>'org';

    -- Validar datos mínimos
    IF v_country_name IS NULL OR v_city IS NULL THEN
        RAISE EXCEPTION 'Datos de geolocalización incompletos: país=%, ciudad=%', v_country_name, v_city;
    END IF;

    -- Intentar actualizar registro existente
    UPDATE geolocalizacion_usuarios
    SET
        ultima_visita = NOW(),
        visitas_totales = visitas_totales + 1,
        datos_raw = p_datos_geo,
        updated_at = NOW()
    WHERE usuario_id = p_usuario_id AND ip = v_ip_inet
    RETURNING id INTO v_registro_id;

    -- Si no existe, crear nuevo registro
    IF v_registro_id IS NULL THEN
        INSERT INTO geolocalizacion_usuarios (
            usuario_id,
            ip,
            pais,
            pais_codigo,
            region,
            ciudad,
            latitud,
            longitud,
            zona_horaria,
            isp,
            organizacion,
            tipo_conexion,
            es_movil,
            es_proxy,
            es_vpn,
            moneda,
            idioma,
            bandera_url,
            datos_raw,
            visitas_totales
        ) VALUES (
            p_usuario_id,
            v_ip_inet,
            v_country_name,
            v_country_code,
            v_region,
            v_city,
            v_latitude,
            v_longitude,
            v_timezone,
            v_org,
            v_org,
            'Desconocida', -- ipapi.co no proporciona tipo de conexión específico
            false, -- ipapi.co no proporciona info móvil en plan gratuito
            false, -- ipapi.co no proporciona info proxy en plan gratuito
            false, -- ipapi.co no proporciona info VPN en plan gratuito
            p_datos_geo->>'currency',
            COALESCE(p_datos_geo->>'language', 'es'),
            CONCAT('https://flagcdn.com/32x24/', v_country_code, '.png'),
            p_datos_geo,
            1
        )
        RETURNING id INTO v_registro_id;
    END IF;

    RETURN v_registro_id;

EXCEPTION WHEN OTHERS THEN
    -- Log del error para debugging
    RAISE LOG 'Error en upsert_geolocalizacion_usuario: %, Datos: %', SQLERRM, p_datos_geo;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener estadísticas optimizada para ipapi.co
CREATE OR REPLACE FUNCTION public.obtener_estadisticas_geograficas()
RETURNS TABLE(
    pais VARCHAR(100),
    total_usuarios BIGINT,
    total_visitas BIGINT,
    usuarios_moviles BIGINT,
    usuarios_vpn BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        g.pais,
        COUNT(DISTINCT g.usuario_id)::BIGINT as total_usuarios,
        COALESCE(SUM(g.visitas_totales), 0)::BIGINT as total_visitas,
        COUNT(DISTINCT CASE WHEN g.es_movil THEN g.usuario_id END)::BIGINT as usuarios_moviles,
        COUNT(DISTINCT CASE WHEN g.es_vpn THEN g.usuario_id END)::BIGINT as usuarios_vpn
    FROM geolocalizacion_usuarios g
    WHERE g.pais IS NOT NULL
    GROUP BY g.pais
    ORDER BY total_usuarios DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para test de ipapi.co (solo para debugging)
CREATE OR REPLACE FUNCTION public.test_ipapi_geolocalizacion()
RETURNS TEXT AS $$
DECLARE
    test_data JSONB;
    test_user_id UUID;
    result UUID;
BEGIN
    -- Datos de ejemplo de ipapi.co
    test_data := '{
        "ip": "190.144.200.123",
        "city": "Valledupar",
        "region": "Cesar",
        "country_name": "Colombia", 
        "country_code": "CO",
        "latitude": 10.4631,
        "longitude": -73.2533,
        "timezone": "America/Bogota",
        "org": "COLOMBIA TELECOMUNICACIONES S.A. ESP",
        "currency": "COP",
        "language": "es"
    }'::JSONB;

    -- Obtener el primer usuario disponible
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;

    IF test_user_id IS NULL THEN
        RETURN '❌ No hay usuarios disponibles para test';
    END IF;

    -- Probar la función
    SELECT upsert_geolocalizacion_usuario(
        test_user_id,
        '190.144.200.123',
        test_data
    ) INTO result;

    IF result IS NOT NULL THEN
        RETURN '✅ Test exitoso - Función ipapi.co funcionando correctamente';
    ELSE
        RETURN '❌ Test falló - Error en función ipapi.co';
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN '❌ Error en test: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ejecutar test automático
SELECT test_ipapi_geolocalizacion() as resultado_test;

-- Verificar estructura de tabla
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'geolocalizacion_usuarios' 
ORDER BY ordinal_position;

SELECT '🎉 ¡Función SQL optimizada para ipapi.co lista!' as estado; 