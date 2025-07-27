# 🚀 **CONFIGURACIÓN REALTIME SUPABASE - PASO A PASO**

## **📋 CHECKLIST COMPLETO**

### **🔥 PASO 1: EJECUTAR SQL EN SUPABASE**

Ve a **Supabase Dashboard → SQL Editor** y ejecuta:

```sql
-- ============================================
-- HABILITAR REALTIME EN TABLAS DE MENSAJERÍA
-- ============================================

-- 1. Habilitar Realtime en tabla mensajes
ALTER PUBLICATION supabase_realtime ADD TABLE mensajes;

-- 2. Habilitar Realtime en tabla chats  
ALTER PUBLICATION supabase_realtime ADD TABLE chats;

-- 3. Habilitar Realtime en tabla miembros_chat
ALTER PUBLICATION supabase_realtime ADD TABLE miembros_chat;

-- ============================================
-- POLÍTICAS RLS PARA REALTIME
-- ============================================

-- 4. Política para SELECT en mensajes (necesaria para Realtime)
CREATE POLICY "realtime_mensajes_select" ON mensajes
FOR SELECT USING (
    auth.uid() IN (
        SELECT usuario_id FROM miembros_chat 
        WHERE chat_id = mensajes.chat_id
    )
);

-- 5. Política para INSERT en mensajes (necesaria para Realtime)
CREATE POLICY "realtime_mensajes_insert" ON mensajes
FOR INSERT WITH CHECK (
    auth.uid() IN (
        SELECT usuario_id FROM miembros_chat 
        WHERE chat_id = mensajes.chat_id 
        AND puede_escribir = true
    )
);

-- 6. Política para UPDATE en mensajes
CREATE POLICY "realtime_mensajes_update" ON mensajes
FOR UPDATE USING (
    usuario_id = auth.uid() OR 
    auth.uid() IN (
        SELECT usuario_id FROM miembros_chat 
        WHERE chat_id = mensajes.chat_id 
        AND es_admin = true
    )
);

-- ============================================
-- VERIFICAR CONFIGURACIÓN REALTIME
-- ============================================

-- 7. Verificar que las tablas estén en la publicación
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';

-- 8. Mostrar políticas RLS activas
SELECT schemaname, tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('mensajes', 'chats', 'miembros_chat');
```

---

### **🔍 PASO 2: VERIFICAR EN CONSOLA DEL NAVEGADOR**

1. **Abre la consola** (F12) en tu aplicación
2. **Ve a la página de mensajes**
3. **Busca estos logs:**
   ```
   ✅ [REALTIME] Conectado exitosamente al chat [ID]
   🔗 [REALTIME] Estado del canal [ID]: SUBSCRIBED
   ```

---

### **📱 PASO 3: PROBAR CON DOS USUARIOS**

1. **Usuario 1:** Abre la conversación en una ventana
2. **Usuario 2:** Abre la misma conversación en otra ventana/navegador
3. **Envía un mensaje** desde Usuario 1
4. **Verifica que llegue inmediatamente** a Usuario 2

---

### **🚨 PASO 4: TROUBLESHOOTING**

#### **Si no funciona, verificar:**

1. **¿Las políticas RLS están bien?**
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'mensajes';
   ```

2. **¿Los usuarios son miembros del chat?**
   ```sql
   SELECT * FROM miembros_chat WHERE chat_id = 'TU_CHAT_ID';
   ```

3. **¿El Realtime está habilitado?**
   ```sql
   SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
   ```

---

### **🎯 INDICADORES VISUALES**

En el header del chat verás:
- 🟢 **"Tiempo real"** = ✅ Conectado
- 🟡 **"Conectando..."** = ⏳ Estableciendo conexión
- 🔴 **"Sin conexión"** = ❌ Problema de conexión

---

### **📞 SI SIGUE SIN FUNCIONAR**

1. **Reinicia la aplicación** completamente
2. **Limpia el caché** del navegador
3. **Verifica que ambos usuarios estén autenticados**
4. **Revisa la consola** en busca de errores específicos

---

## **🔧 COMANDOS DE DEPURACIÓN**

```sql
-- Ver todos los chats del usuario actual
SELECT c.*, m.usuario_id, m.es_admin 
FROM chats c
JOIN miembros_chat m ON c.id = m.chat_id
WHERE m.usuario_id = auth.uid();

-- Ver mensajes de un chat específico
SELECT * FROM mensajes 
WHERE chat_id = 'TU_CHAT_ID' 
ORDER BY creado_en DESC 
LIMIT 10;

-- Verificar permisos del usuario en un chat
SELECT * FROM miembros_chat 
WHERE chat_id = 'TU_CHAT_ID' 
AND usuario_id = auth.uid();
```

---

**✅ Una vez completados todos los pasos, el tiempo real debería funcionar perfectamente!** 