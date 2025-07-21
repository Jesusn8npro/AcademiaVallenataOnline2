-- Verificar y arreglar estructura de tabla inscripciones
-- Ejecutar en SQL Editor de Supabase

-- 1. Verificar estructura actual de la tabla inscripciones
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'inscripciones'
ORDER BY ordinal_position;

-- 2. Agregar campo paquete_id si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'inscripciones' 
        AND column_name = 'paquete_id'
    ) THEN
        ALTER TABLE inscripciones ADD COLUMN paquete_id UUID;
        ALTER TABLE inscripciones ADD CONSTRAINT inscripciones_paquete_id_fkey 
            FOREIGN KEY (paquete_id) REFERENCES paquetes_tutoriales(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 3. Verificar estructura después del cambio
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'inscripciones'
ORDER BY ordinal_position;

-- 4. Inscribir tutoriales individuales para paquetes existentes
-- (Cambiar los IDs por los reales)
INSERT INTO inscripciones (
    usuario_id,
    tutorial_id,
    fecha_inscripcion,
    porcentaje_completado,
    completado,
    estado,
    progreso,
    ultima_actividad
) 
SELECT DISTINCT
    i.usuario_id,
    pti.tutorial_id,
    NOW(),
    0,
    false,
    'activo',
    0,
    NOW()
FROM inscripciones i
JOIN paquetes_tutoriales_items pti ON i.paquete_id = pti.paquete_id
WHERE i.paquete_id IS NOT NULL
  AND pti.incluido = true
  AND NOT EXISTS (
    SELECT 1 FROM inscripciones i2 
    WHERE i2.usuario_id = i.usuario_id 
      AND i2.tutorial_id = pti.tutorial_id
  );

-- 5. Verificar que se crearon correctamente
SELECT 
    COUNT(*) as total_inscripciones,
    COUNT(CASE WHEN curso_id IS NOT NULL THEN 1 END) as cursos,
    COUNT(CASE WHEN tutorial_id IS NOT NULL THEN 1 END) as tutoriales,
    COUNT(CASE WHEN paquete_id IS NOT NULL THEN 1 END) as paquetes
FROM inscripciones; 