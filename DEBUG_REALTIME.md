# 🐛 **DEBUG TIEMPO REAL - GUÍA PASO A PASO**

## **🔍 PASOS PARA VERIFICAR QUE FUNCIONA**

### **1. 📱 PREPARAR DOS VENTANAS**
- **Ventana 1:** Usuario A - abre el chat
- **Ventana 2:** Usuario B - abre el mismo chat
- **IMPORTANTE:** Asegúrate de que ambos sean miembros del chat

### **2. 🔎 ABRIR CONSOLA EN AMBAS VENTANAS**
Presiona `F12` y ve a la pestaña "Console"

### **3. 📊 BUSCAR ESTOS LOGS**

#### **✅ AL CARGAR EL CHAT, DEBES VER:**
```
📥 [CARGAR] Iniciando carga de mensajes para chat: [ID]
✅ [CARGAR] X mensajes obtenidos
✅ [CARGAR] Mensajes cargados y mostrados correctamente
🔄 [CARGAR] Proceso de carga finalizado
```

#### **✅ AL CONFIGURAR TIEMPO REAL:**
```
🔴 [CHAT-VISTA] Configurando tiempo real para chat: [ID]
🔗 [REALTIME] Estado: SUBSCRIBED
✅ [REALTIME] Conectado al chat [ID]
```

#### **✅ AL ENVIAR UN MENSAJE:**
**En la ventana del emisor:**
```
📤 [ENVIAR] Mensaje temporal creado
📤 [ENVIAR] Mensaje enviado correctamente
```

**En la ventana del receptor:**
```
📨 [REALTIME] Nuevo mensaje recibido: [ID]
✅ [REALTIME] Mensaje de otro usuario agregado: [ID]
```

---

## **🚨 POSIBLES PROBLEMAS Y SOLUCIONES**

### **❌ PROBLEMA: "Estado: CONNECTING" infinito**
**Causa:** Realtime no habilitado en Supabase
**Solución:** Ejecutar el SQL de `REALTIME_SETUP_SUPABASE.md`

### **❌ PROBLEMA: No aparecen logs de "[REALTIME]"**
**Causa:** Suscripción fallida
**Solución:** 
1. Recargar la página
2. Verificar que ambos usuarios son miembros del chat
3. Revisar políticas RLS en Supabase

### **❌ PROBLEMA: Mensajes llegan pero duplicados**
**Causa:** Múltiples suscripciones
**Solución:** Recargar la página completamente

### **❌ PROBLEMA: "Error 403" en logs**
**Causa:** Políticas RLS muy restrictivas
**Solución:** Verificar que las políticas permiten SELECT/INSERT

---

## **🔧 COMANDOS DE VERIFICACIÓN**

### **En Supabase SQL Editor:**

```sql
-- 1. Verificar que Realtime está habilitado
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

-- 2. Verificar miembros del chat
SELECT * FROM miembros_chat WHERE chat_id = 'TU_CHAT_ID';

-- 3. Ver políticas RLS
SELECT * FROM pg_policies WHERE tablename = 'mensajes';
```

---

## **🎯 INDICADORES VISUALES**

En el header del chat verás:
- 🟢 **"Tiempo real"** = ✅ TODO BIEN
- 🟡 **"Conectando..."** = ⏳ Estableciendo conexión
- 🔴 **"Sin conexión"** = ❌ Problema

---

## **✅ PRUEBA DEFINITIVA**

1. **Usuario A** envía: "Hola desde A"
2. **Usuario B** debería verlo **inmediatamente** sin refrescar
3. **Usuario B** responde: "Hola desde B"  
4. **Usuario A** debería verlo **inmediatamente**

**Si esto funciona = ✅ TIEMPO REAL CONFIGURADO CORRECTAMENTE**

---

## **📞 SI SIGUE SIN FUNCIONAR**

1. **Borrar caché** del navegador (Ctrl+Shift+R)
2. **Recargar** ambas ventanas
3. **Verificar** que ambos usuarios están autenticados
4. **Revisar** la pestaña Network en DevTools para errores HTTP

---

**💡 TIP:** Los logs están organizados con prefijos para facilitar el debugging:
- `[CARGAR]` = Carga inicial de mensajes
- `[REALTIME]` = Eventos de tiempo real
- `[ENVIAR]` = Envío de mensajes
- `[CHAT-VISTA]` = Gestión del componente 