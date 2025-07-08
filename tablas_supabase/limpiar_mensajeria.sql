-- ============================================
-- SCRIPT DE LIMPIEZA - SISTEMA DE MENSAJERÍA
-- ============================================
-- Ejecutar ANTES de crear las tablas nuevas
-- Elimina TODA la infraestructura de mensajería

-- ============================================
-- 1. ELIMINAR POLÍTICAS RLS
-- ============================================

-- Desactivar RLS y eliminar políticas existentes
ALTER TABLE IF EXISTS chats DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS miembros_chat DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS mensajes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS mensajes_lectura DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS mensajes_lecturas DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS mensajes_reacciones DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS chats_configuracion DISABLE ROW LEVEL SECURITY;

-- Eliminar todas las políticas
DROP POLICY IF EXISTS "usuarios_ven_sus_chats" ON chats;
DROP POLICY IF EXISTS "usuarios_crean_chats" ON chats;
DROP POLICY IF EXISTS "admins_actualizan_chats" ON chats;
DROP POLICY IF EXISTS "solo_miembros_ven_miembros" ON miembros_chat;
DROP POLICY IF EXISTS "crear_miembros_chat" ON miembros_chat;
DROP POLICY IF EXISTS "actualizar_miembros_chat" ON miembros_chat;
DROP POLICY IF EXISTS "miembros_ven_mensajes" ON mensajes;
DROP POLICY IF EXISTS "miembros_envian_mensajes" ON mensajes;
DROP POLICY IF EXISTS "usuarios_editan_sus_mensajes" ON mensajes;
DROP POLICY IF EXISTS "usuarios_gestionan_sus_lecturas" ON mensajes_lectura;
DROP POLICY IF EXISTS "usuarios_gestionan_sus_lecturas" ON mensajes_lecturas;
DROP POLICY IF EXISTS "miembros_ven_reacciones" ON mensajes_reacciones;
DROP POLICY IF EXISTS "usuarios_gestionan_sus_reacciones" ON mensajes_reacciones;
DROP POLICY IF EXISTS "usuarios_eliminan_sus_reacciones" ON mensajes_reacciones;

-- ============================================
-- 2. ELIMINAR TRIGGERS
-- ============================================

DROP TRIGGER IF EXISTS trigger_actualizar_ultimo_mensaje ON mensajes;
DROP TRIGGER IF EXISTS trigger_incrementar_no_leidos ON mensajes;

-- ============================================
-- 3. ELIMINAR FUNCIONES
-- ============================================

DROP FUNCTION IF EXISTS actualizar_ultimo_mensaje_chat() CASCADE;
DROP FUNCTION IF EXISTS incrementar_mensajes_no_leidos() CASCADE;
DROP FUNCTION IF EXISTS marcar_mensajes_como_leidos(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS es_miembro_chat(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS es_admin_chat(UUID, UUID) CASCADE;

-- ============================================
-- 4. ELIMINAR VISTAS
-- ============================================

DROP VIEW IF EXISTS vista_chats_usuario CASCADE;

-- ============================================
-- 5. ELIMINAR TABLAS EN ORDEN CORRECTO
-- ============================================

-- Eliminar tablas dependientes primero
DROP TABLE IF EXISTS mensajes_reacciones CASCADE;
DROP TABLE IF EXISTS mensajes_lectura CASCADE;
DROP TABLE IF EXISTS mensajes_lecturas CASCADE; -- Por si había la tabla con nombre incorrecto
DROP TABLE IF EXISTS mensajes CASCADE;
DROP TABLE IF EXISTS miembros_chat CASCADE;
DROP TABLE IF EXISTS chats_configuracion CASCADE;
DROP TABLE IF EXISTS chats CASCADE;

-- ============================================
-- 6. LIMPIAR ÍNDICES HUÉRFANOS (si los hay)
-- ============================================

-- Los índices se eliminan automáticamente con las tablas,
-- pero por si acaso eliminamos cualquier índice huérfano
DROP INDEX IF EXISTS idx_chats_usuario_creador;
DROP INDEX IF EXISTS idx_chats_tipo;
DROP INDEX IF EXISTS idx_chats_activo;
DROP INDEX IF EXISTS idx_miembros_chat_usuario;
DROP INDEX IF EXISTS idx_miembros_chat_estado;
DROP INDEX IF EXISTS idx_miembros_no_leidos;
DROP INDEX IF EXISTS idx_mensajes_chat_fecha;
DROP INDEX IF EXISTS idx_mensajes_usuario;
DROP INDEX IF EXISTS idx_mensajes_tipo;
DROP INDEX IF EXISTS idx_lectura_usuario;
DROP INDEX IF EXISTS idx_lectura_mensaje;
DROP INDEX IF EXISTS idx_lecturas_usuario;
DROP INDEX IF EXISTS idx_lecturas_mensaje;
DROP INDEX IF EXISTS idx_reacciones_mensaje;
DROP INDEX IF EXISTS idx_reacciones_usuario;

-- ============================================
-- CONFIRMACIÓN
-- ============================================

-- Verificar que todo fue eliminado
DO $$
BEGIN
    RAISE NOTICE '✅ Limpieza completada. Todas las tablas de mensajería han sido eliminadas.';
    RAISE NOTICE '🔄 Ahora ejecuta el archivo tablas_mensajeria.sql para recrear todo.';
END $$; 