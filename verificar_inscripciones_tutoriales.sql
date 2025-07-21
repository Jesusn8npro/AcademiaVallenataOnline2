-- Script para verificar inscripciones de tutoriales
-- Ejecutar en el SQL Editor de Supabase

-- 1. Verificar estructura de la tabla inscripciones
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'inscripciones'
ORDER BY ordinal_position;

-- 2. Verificar inscripciones existentes
SELECT 
    id,
    usuario_id,
    curso_id,
    tutorial_id,
    paquete_id,
    fecha_inscripcion,
    estado,
    completado
FROM inscripciones
WHERE usuario_id = 'cd27790-fc28-427e-9cba-cc751ae3d736' -- Cambiar por ID real
ORDER BY fecha_inscripcion DESC;

-- 3. Verificar paquetes inscritos
SELECT 
    i.id,
    i.paquete_id,
    pt.titulo as paquete_titulo,
    i.fecha_inscripcion
FROM inscripciones i
JOIN paquetes_tutoriales pt ON i.paquete_id = pt.id
WHERE i.usuario_id = 'cd27790-fc28-427e-9cba-cc751ae3d736' -- Cambiar por ID real
ORDER BY i.fecha_inscripcion DESC;

-- 4. Verificar tutoriales de un paquete específico
SELECT 
    pti.id,
    pti.paquete_id,
    pti.tutorial_id,
    pti.orden,
    pti.incluido,
    t.titulo as tutorial_titulo,
    t.descripcion_corta
FROM paquetes_tutoriales_items pti
JOIN tutoriales t ON pti.tutorial_id = t.id
WHERE pti.paquete_id = '91222747-5518-4686-ae5e-a8fd04a2c697' -- Cambiar por ID de paquete real
  AND pti.incluido = true
ORDER BY pti.orden;

-- 5. Insertar tutoriales manualmente (cambiar IDs por reales)
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
SELECT 
    'cd27790-fc28-427e-9cba-cc751ae3d736', -- ID del usuario
    pti.tutorial_id,
    NOW(),
    0,
    false,
    'activo',
    0,
    NOW()
FROM paquetes_tutoriales_items pti
WHERE pti.paquete_id = '91222747-5518-4686-ae5e-a8fd04a2c697' -- ID del paquete
  AND pti.incluido = true
  AND pti.tutorial_id NOT IN (
    SELECT tutorial_id 
    FROM inscripciones 
    WHERE usuario_id = 'cd27790-fc28-427e-9cba-cc751ae3d736' 
      AND tutorial_id IS NOT NULL
  );

-- 6. Verificar que se insertaron correctamente
SELECT 
    i.id,
    i.tutorial_id,
    t.titulo as tutorial_titulo,
    i.fecha_inscripcion
FROM inscripciones i
JOIN tutoriales t ON i.tutorial_id = t.id
WHERE i.usuario_id = 'cd27790-fc28-427e-9cba-cc751ae3d736' -- Cambiar por ID real
ORDER BY i.fecha_inscripcion DESC;

-- 7. Limpiar inscripciones de prueba (si es necesario)
-- DELETE FROM inscripciones 
-- WHERE usuario_id = 'cd27790-fc28-427e-9cba-cc751ae3d736' 
--   AND tutorial_id IS NOT NULL; 