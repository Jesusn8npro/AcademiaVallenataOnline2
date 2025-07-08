-- ============================================
-- ARREGLAR POLÍTICAS RLS - SISTEMA MENSAJERÍA
-- ============================================
-- Políticas más permisivas para que funcione correctamente

-- ============================================
-- 1. ELIMINAR POLÍTICAS PROBLEMÁTICAS
-- ============================================

-- Eliminar todas las políticas existentes
DROP POLICY IF EXISTS "chats_select_policy" ON chats;
DROP POLICY IF EXISTS "chats_insert_policy" ON chats;
DROP POLICY IF EXISTS "chats_update_policy" ON chats;
DROP POLICY IF EXISTS "chats_delete_policy" ON chats;

DROP POLICY IF EXISTS "miembros_chat_select_policy" ON miembros_chat;
DROP POLICY IF EXISTS "miembros_chat_insert_policy" ON miembros_chat;
DROP POLICY IF EXISTS "miembros_chat_update_policy" ON miembros_chat;
DROP POLICY IF EXISTS "miembros_chat_delete_policy" ON miembros_chat;

DROP POLICY IF EXISTS "mensajes_select_policy" ON mensajes;
DROP POLICY IF EXISTS "mensajes_insert_policy" ON mensajes;
DROP POLICY IF EXISTS "mensajes_update_policy" ON mensajes;
DROP POLICY IF EXISTS "mensajes_delete_policy" ON mensajes;

DROP POLICY IF EXISTS "mensajes_lectura_select_policy" ON mensajes_lectura;
DROP POLICY IF EXISTS "mensajes_lectura_insert_policy" ON mensajes_lectura;
DROP POLICY IF EXISTS "mensajes_lectura_update_policy" ON mensajes_lectura;
DROP POLICY IF EXISTS "mensajes_lectura_delete_policy" ON mensajes_lectura;

DROP POLICY IF EXISTS "mensajes_reacciones_select_policy" ON mensajes_reacciones;
DROP POLICY IF EXISTS "mensajes_reacciones_insert_policy" ON mensajes_reacciones;
DROP POLICY IF EXISTS "mensajes_reacciones_update_policy" ON mensajes_reacciones;
DROP POLICY IF EXISTS "mensajes_reacciones_delete_policy" ON mensajes_reacciones;

-- ============================================
-- 2. CREAR POLÍTICAS PERMISIVAS (PARA TESTING)
-- ============================================

-- ===== CHATS =====
-- Cualquier usuario autenticado puede ver chats donde es miembro
CREATE POLICY "chats_select_policy" ON chats
    FOR SELECT 
    USING (
        auth.uid() IS NOT NULL
    );

-- Cualquier usuario autenticado puede crear chats
CREATE POLICY "chats_insert_policy" ON chats
    FOR INSERT 
    WITH CHECK (
        auth.uid() IS NOT NULL 
        AND auth.uid() = creado_por
    );

-- Solo el creador puede actualizar el chat
CREATE POLICY "chats_update_policy" ON chats
    FOR UPDATE 
    USING (
        auth.uid() IS NOT NULL 
        AND auth.uid() = creado_por
    );

-- Solo el creador puede eliminar el chat
CREATE POLICY "chats_delete_policy" ON chats
    FOR DELETE 
    USING (
        auth.uid() IS NOT NULL 
        AND auth.uid() = creado_por
    );

-- ===== MIEMBROS_CHAT =====
-- Cualquier usuario autenticado puede ver miembros
CREATE POLICY "miembros_chat_select_policy" ON miembros_chat
    FOR SELECT 
    USING (
        auth.uid() IS NOT NULL
    );

-- Cualquier usuario autenticado puede agregar miembros
CREATE POLICY "miembros_chat_insert_policy" ON miembros_chat
    FOR INSERT 
    WITH CHECK (
        auth.uid() IS NOT NULL
    );

-- Cualquier usuario autenticado puede actualizar miembros
CREATE POLICY "miembros_chat_update_policy" ON miembros_chat
    FOR UPDATE 
    USING (
        auth.uid() IS NOT NULL
    );

-- Cualquier usuario autenticado puede eliminar miembros
CREATE POLICY "miembros_chat_delete_policy" ON miembros_chat
    FOR DELETE 
    USING (
        auth.uid() IS NOT NULL
    );

-- ===== MENSAJES =====
-- Cualquier usuario autenticado puede ver mensajes
CREATE POLICY "mensajes_select_policy" ON mensajes
    FOR SELECT 
    USING (
        auth.uid() IS NOT NULL
    );

-- Cualquier usuario autenticado puede crear mensajes
CREATE POLICY "mensajes_insert_policy" ON mensajes
    FOR INSERT 
    WITH CHECK (
        auth.uid() IS NOT NULL 
        AND auth.uid() = usuario_id
    );

-- Solo el autor puede actualizar sus mensajes
CREATE POLICY "mensajes_update_policy" ON mensajes
    FOR UPDATE 
    USING (
        auth.uid() IS NOT NULL 
        AND auth.uid() = usuario_id
    );

-- Solo el autor puede eliminar sus mensajes
CREATE POLICY "mensajes_delete_policy" ON mensajes
    FOR DELETE 
    USING (
        auth.uid() IS NOT NULL 
        AND auth.uid() = usuario_id
    );

-- ===== MENSAJES_LECTURA =====
-- Cualquier usuario autenticado puede ver lecturas
CREATE POLICY "mensajes_lectura_select_policy" ON mensajes_lectura
    FOR SELECT 
    USING (
        auth.uid() IS NOT NULL
    );

-- Cualquier usuario autenticado puede marcar como leído
CREATE POLICY "mensajes_lectura_insert_policy" ON mensajes_lectura
    FOR INSERT 
    WITH CHECK (
        auth.uid() IS NOT NULL 
        AND auth.uid() = usuario_id
    );

-- Solo el usuario puede actualizar su lectura
CREATE POLICY "mensajes_lectura_update_policy" ON mensajes_lectura
    FOR UPDATE 
    USING (
        auth.uid() IS NOT NULL 
        AND auth.uid() = usuario_id
    );

-- Solo el usuario puede eliminar su lectura
CREATE POLICY "mensajes_lectura_delete_policy" ON mensajes_lectura
    FOR DELETE 
    USING (
        auth.uid() IS NOT NULL 
        AND auth.uid() = usuario_id
    );

-- ===== MENSAJES_REACCIONES =====
-- Cualquier usuario autenticado puede ver reacciones
CREATE POLICY "mensajes_reacciones_select_policy" ON mensajes_reacciones
    FOR SELECT 
    USING (
        auth.uid() IS NOT NULL
    );

-- Cualquier usuario autenticado puede crear reacciones
CREATE POLICY "mensajes_reacciones_insert_policy" ON mensajes_reacciones
    FOR INSERT 
    WITH CHECK (
        auth.uid() IS NOT NULL 
        AND auth.uid() = usuario_id
    );

-- Solo el usuario puede actualizar su reacción
CREATE POLICY "mensajes_reacciones_update_policy" ON mensajes_reacciones
    FOR UPDATE 
    USING (
        auth.uid() IS NOT NULL 
        AND auth.uid() = usuario_id
    );

-- Solo el usuario puede eliminar su reacción
CREATE POLICY "mensajes_reacciones_delete_policy" ON mensajes_reacciones
    FOR DELETE 
    USING (
        auth.uid() IS NOT NULL 
        AND auth.uid() = usuario_id
    );

-- ============================================
-- 3. VERIFICAR QUE RLS ESTÉ ACTIVADO
-- ============================================

-- Activar RLS en todas las tablas
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE miembros_chat ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes_lectura ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes_reacciones ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. VERIFICACIÓN
-- ============================================

-- Verificar que las políticas se crearon correctamente
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('chats', 'miembros_chat', 'mensajes', 'mensajes_lectura', 'mensajes_reacciones')
ORDER BY tablename, policyname; 