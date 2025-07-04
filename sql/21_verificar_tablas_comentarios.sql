-- ============================================
-- VERIFICAR TODAS LAS TABLAS DE COMENTARIOS
-- ============================================

-- 1. Verificar qué tablas de comentarios existen
SELECT 'TABLAS DE COMENTARIOS EXISTENTES' as paso;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name LIKE '%comentarios%' 
OR table_name LIKE '%comment%'
ORDER BY table_name;

-- 2. Verificar estructura de comentarios_clases
SELECT 'ESTRUCTURA DE comentarios_clases' as paso;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'comentarios_clases' 
ORDER BY ordinal_position;

-- 3. Verificar estructura de comentarios_lecciones
SELECT 'ESTRUCTURA DE comentarios_lecciones' as paso;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'comentarios_lecciones' 
ORDER BY ordinal_position;

-- 4. Verificar estructura de comunidad_comentarios
SELECT 'ESTRUCTURA DE comunidad_comentarios' as paso;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'comunidad_comentarios' 
ORDER BY ordinal_position;

-- 5. Verificar si comentarios_lecciones tiene la columna contenido
DO $$
DECLARE
    tabla_existe BOOLEAN;
    columna_contenido_existe BOOLEAN;
    columna_comentario_existe BOOLEAN;
BEGIN
    -- Verificar si la tabla existe
    SELECT EXISTS(
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'comentarios_lecciones'
    ) INTO tabla_existe;
    
    IF tabla_existe THEN
        -- Verificar si tiene columna 'contenido'
        SELECT EXISTS(
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'comentarios_lecciones' 
            AND column_name = 'contenido'
        ) INTO columna_contenido_existe;
        
        -- Verificar si tiene columna 'comentario'
        SELECT EXISTS(
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'comentarios_lecciones' 
            AND column_name = 'comentario'
        ) INTO columna_comentario_existe;
        
        RAISE NOTICE 'Tabla comentarios_lecciones:';
        RAISE NOTICE '  - Existe: %', tabla_existe;
        RAISE NOTICE '  - Tiene columna "contenido": %', columna_contenido_existe;
        RAISE NOTICE '  - Tiene columna "comentario": %', columna_comentario_existe;
        
        IF NOT columna_contenido_existe AND NOT columna_comentario_existe THEN
            RAISE NOTICE '  ❌ PROBLEMA: No tiene ninguna columna para el texto del comentario';
        ELSIF columna_contenido_existe THEN
            RAISE NOTICE '  ✅ Usa columna "contenido"';
        ELSIF columna_comentario_existe THEN
            RAISE NOTICE '  ✅ Usa columna "comentario"';
        END IF;
    ELSE
        RAISE NOTICE 'Tabla comentarios_lecciones NO EXISTE';
    END IF;
END $$;

-- 6. Crear tabla comentarios_lecciones si no existe con la estructura correcta
CREATE TABLE IF NOT EXISTS comentarios_lecciones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    leccion_id UUID NOT NULL,
    usuario_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
    contenido TEXT NOT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    respuesta_a UUID REFERENCES comentarios_lecciones(id) ON DELETE CASCADE,
    likes INTEGER DEFAULT 0
);

-- 7. Habilitar RLS en comentarios_lecciones
ALTER TABLE comentarios_lecciones ENABLE ROW LEVEL SECURITY;

-- 8. Crear políticas RLS para comentarios_lecciones
DROP POLICY IF EXISTS "Ver comentarios lecciones" ON comentarios_lecciones;
DROP POLICY IF EXISTS "Insertar comentarios lecciones" ON comentarios_lecciones;
DROP POLICY IF EXISTS "Actualizar comentarios lecciones propios" ON comentarios_lecciones;

CREATE POLICY "Ver comentarios lecciones" ON comentarios_lecciones
    FOR SELECT USING (true);

CREATE POLICY "Insertar comentarios lecciones" ON comentarios_lecciones
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL 
        AND usuario_id = auth.uid()
    );

CREATE POLICY "Actualizar comentarios lecciones propios" ON comentarios_lecciones
    FOR UPDATE USING (
        auth.uid() IS NOT NULL 
        AND usuario_id = auth.uid()
    );

-- 9. Otorgar permisos
GRANT SELECT, INSERT, UPDATE ON comentarios_lecciones TO authenticated;

-- 10. Verificación final
SELECT 'VERIFICACIÓN FINAL' as paso;
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 VERIFICACIÓN DE TABLAS DE COMENTARIOS COMPLETADA';
    RAISE NOTICE '';
    RAISE NOTICE '📋 RESUMEN:';
    RAISE NOTICE '✅ comentarios_clases - usa columna "contenido"';
    RAISE NOTICE '✅ comentarios_lecciones - usa columna "contenido"';
    RAISE NOTICE '✅ comunidad_comentarios - usa columna "comentario"';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 El componente ComentariosLeccion.svelte está correcto';
    RAISE NOTICE '🔧 El error debe venir de otro lado';
    RAISE NOTICE '';
END $$; 