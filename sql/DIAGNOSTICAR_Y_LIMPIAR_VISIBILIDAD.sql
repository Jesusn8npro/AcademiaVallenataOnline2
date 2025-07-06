-- ===== DIAGNOSTICAR Y LIMPIAR VALORES DE VISIBILIDAD =====
-- Este script encuentra y corrige los valores problemáticos

-- 1. VER QUÉ VALORES ÚNICOS HAY ACTUALMENTE
SELECT DISTINCT visibilidad, COUNT(*) as cantidad
FROM comunidad_publicaciones 
GROUP BY visibilidad
ORDER BY cantidad DESC;

-- 2. VER REGISTROS CON VALORES PROBLEMÁTICOS (que no sean los permitidos)
SELECT id, usuario_nombre, tipo, visibilidad, fecha_creacion
FROM comunidad_publicaciones 
WHERE visibilidad NOT IN ('publico', 'privado', 'amigos')
ORDER BY fecha_creacion DESC
LIMIT 10;

-- 3. ACTUALIZAR VALORES PROBLEMÁTICOS A 'publico'
UPDATE comunidad_publicaciones 
SET visibilidad = 'publico' 
WHERE visibilidad NOT IN ('publico', 'privado', 'amigos');

-- 4. CONFIRMAR QUE YA NO HAY VALORES PROBLEMÁTICOS
SELECT DISTINCT visibilidad, COUNT(*) as cantidad
FROM comunidad_publicaciones 
GROUP BY visibilidad
ORDER BY cantidad DESC;

-- 5. AHORA SÍ ELIMINAR EL CONSTRAINT PROBLEMÁTICO
ALTER TABLE comunidad_publicaciones DROP CONSTRAINT IF EXISTS comunidad_publicaciones_visibilidad_check;

-- 6. CREAR EL CONSTRAINT CORRECTO
ALTER TABLE comunidad_publicaciones 
ADD CONSTRAINT comunidad_publicaciones_visibilidad_check 
CHECK (visibilidad IN ('publico', 'privado', 'amigos'));

-- 7. CONFIRMACIÓN FINAL
SELECT '✅ SOLUCIONADO! Valores limpiados y constraint aplicado correctamente' as resultado; 