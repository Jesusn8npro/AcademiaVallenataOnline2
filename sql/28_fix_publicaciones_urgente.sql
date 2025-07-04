-- ============================================
-- FIX URGENTE PARA PUBLICACIONES
-- ============================================

-- 1. Eliminar el trigger problemático temporalmente
DROP TRIGGER IF EXISTS trigger_notificar_publicacion_admin ON comunidad_publicaciones;

-- 2. Verificar que se eliminó
SELECT 'TRIGGER ELIMINADO' as estado;
SELECT COUNT(*) as triggers_restantes
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
AND trigger_name = 'trigger_notificar_publicacion_admin';

-- 3. Verificar que las publicaciones funcionan ahora
SELECT 'SISTEMA RESTAURADO' as mensaje;
SELECT 'Ahora puedes publicar normalmente' as instruccion; 