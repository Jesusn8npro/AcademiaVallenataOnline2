-- ============================================
-- ARREGLAR RELACIONES CLAVES FORÁNEAS
-- ============================================
-- Problema: Supabase no encuentra las relaciones entre tablas

-- ============================================
-- 1. VERIFICAR RESTRICCIONES EXISTENTES
-- ============================================

-- Ver todas las restricciones de claves foráneas actuales
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name IN ('chats', 'miembros_chat', 'mensajes', 'mensajes_lectura', 'mensajes_reacciones')
ORDER BY tc.table_name;

-- ============================================
-- 2. ELIMINAR RESTRICCIONES PROBLEMÁTICAS
-- ============================================

-- Eliminar todas las FK existentes (por si están mal nombradas)
ALTER TABLE mensajes DROP CONSTRAINT IF EXISTS mensajes_chat_id_fkey;
ALTER TABLE mensajes DROP CONSTRAINT IF EXISTS mensajes_usuario_id_fkey;
ALTER TABLE mensajes DROP CONSTRAINT IF EXISTS mensajes_mensaje_padre_id_fkey;

ALTER TABLE miembros_chat DROP CONSTRAINT IF EXISTS miembros_chat_chat_id_fkey;
ALTER TABLE miembros_chat DROP CONSTRAINT IF EXISTS miembros_chat_usuario_id_fkey;

ALTER TABLE mensajes_lectura DROP CONSTRAINT IF EXISTS mensajes_lectura_mensaje_id_fkey;
ALTER TABLE mensajes_lectura DROP CONSTRAINT IF EXISTS mensajes_lectura_usuario_id_fkey;

ALTER TABLE mensajes_reacciones DROP CONSTRAINT IF EXISTS mensajes_reacciones_mensaje_id_fkey;
ALTER TABLE mensajes_reacciones DROP CONSTRAINT IF EXISTS mensajes_reacciones_usuario_id_fkey;

ALTER TABLE chats DROP CONSTRAINT IF EXISTS chats_creado_por_fkey;
ALTER TABLE chats DROP CONSTRAINT IF EXISTS chats_ultimo_mensaje_id_fkey;

-- ============================================
-- 3. CREAR CLAVES FORÁNEAS CON NOMBRES ESPECÍFICOS
-- ============================================

-- ===== TABLA: chats =====
-- creado_por → perfiles(id)
ALTER TABLE chats 
ADD CONSTRAINT chats_creado_por_fkey 
FOREIGN KEY (creado_por) REFERENCES perfiles(id) ON DELETE SET NULL;

-- ultimo_mensaje_id → mensajes(id) (se agregará después)

-- ===== TABLA: miembros_chat =====
-- chat_id → chats(id)
ALTER TABLE miembros_chat 
ADD CONSTRAINT miembros_chat_chat_id_fkey 
FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE;

-- usuario_id → perfiles(id)
ALTER TABLE miembros_chat 
ADD CONSTRAINT miembros_chat_usuario_id_fkey 
FOREIGN KEY (usuario_id) REFERENCES perfiles(id) ON DELETE CASCADE;

-- ===== TABLA: mensajes =====
-- chat_id → chats(id)
ALTER TABLE mensajes 
ADD CONSTRAINT mensajes_chat_id_fkey 
FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE;

-- usuario_id → perfiles(id)
ALTER TABLE mensajes 
ADD CONSTRAINT mensajes_usuario_id_fkey 
FOREIGN KEY (usuario_id) REFERENCES perfiles(id) ON DELETE CASCADE;

-- mensaje_padre_id → mensajes(id) (auto-referencia)
ALTER TABLE mensajes 
ADD CONSTRAINT mensajes_mensaje_padre_id_fkey 
FOREIGN KEY (mensaje_padre_id) REFERENCES mensajes(id) ON DELETE SET NULL;

-- ===== TABLA: mensajes_lectura =====
-- mensaje_id → mensajes(id)
ALTER TABLE mensajes_lectura 
ADD CONSTRAINT mensajes_lectura_mensaje_id_fkey 
FOREIGN KEY (mensaje_id) REFERENCES mensajes(id) ON DELETE CASCADE;

-- usuario_id → perfiles(id)
ALTER TABLE mensajes_lectura 
ADD CONSTRAINT mensajes_lectura_usuario_id_fkey 
FOREIGN KEY (usuario_id) REFERENCES perfiles(id) ON DELETE CASCADE;

-- ===== TABLA: mensajes_reacciones =====
-- mensaje_id → mensajes(id)
ALTER TABLE mensajes_reacciones 
ADD CONSTRAINT mensajes_reacciones_mensaje_id_fkey 
FOREIGN KEY (mensaje_id) REFERENCES mensajes(id) ON DELETE CASCADE;

-- usuario_id → perfiles(id)
ALTER TABLE mensajes_reacciones 
ADD CONSTRAINT mensajes_reacciones_usuario_id_fkey 
FOREIGN KEY (usuario_id) REFERENCES perfiles(id) ON DELETE CASCADE;

-- ===== TABLA: chats (relación circular) =====
-- ultimo_mensaje_id → mensajes(id)
ALTER TABLE chats 
ADD CONSTRAINT chats_ultimo_mensaje_id_fkey 
FOREIGN KEY (ultimo_mensaje_id) REFERENCES mensajes(id) ON DELETE SET NULL;

-- ============================================
-- 4. CREAR ÍNDICES PARA RENDIMIENTO
-- ============================================

-- Índices para joins frecuentes
CREATE INDEX IF NOT EXISTS idx_mensajes_chat_id ON mensajes(chat_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_usuario_id ON mensajes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_creado_en ON mensajes(creado_en DESC);

CREATE INDEX IF NOT EXISTS idx_miembros_chat_chat_id ON miembros_chat(chat_id);
CREATE INDEX IF NOT EXISTS idx_miembros_chat_usuario_id ON miembros_chat(usuario_id);

CREATE INDEX IF NOT EXISTS idx_mensajes_lectura_mensaje_id ON mensajes_lectura(mensaje_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_lectura_usuario_id ON mensajes_lectura(usuario_id);

CREATE INDEX IF NOT EXISTS idx_mensajes_reacciones_mensaje_id ON mensajes_reacciones(mensaje_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_reacciones_usuario_id ON mensajes_reacciones(usuario_id);

-- ============================================
-- 5. VERIFICAR QUE TODO ESTÁ BIEN
-- ============================================

-- Verificar que las relaciones se crearon correctamente
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name IN ('chats', 'miembros_chat', 'mensajes', 'mensajes_lectura', 'mensajes_reacciones')
ORDER BY tc.table_name, tc.constraint_name; 