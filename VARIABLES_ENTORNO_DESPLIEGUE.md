# 🔧 CONFIGURACIÓN DE VARIABLES DE ENTORNO

## 📋 VARIABLES NECESARIAS PARA DESPLIEGUE

### **1. SUPABASE (CRÍTICO) 🔥**

```bash
# URL del proyecto Supabase (YA CONFIGURADO)
VITE_SUPABASE_URL=https://tbijzvtyyewhtwgakgka.supabase.co

# Clave pública - Segura para frontend (YA CONFIGURADO)
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NTQyNjIsImV4cCI6MjA1ODUzMDI2Mn0.P09L8OpLpcrm5XzTLAN0oQllhl_bePk5bxbUUpoG-cQ

# ⚠️ FALTA: Clave de servicio (para operaciones admin)
VITE_SUPABASE_SERVICE_ROLE_KEY=[NECESARIO OBTENER]
```

**🔍 Cómo obtener SERVICE_ROLE_KEY:**
1. Ir a: https://supabase.com/dashboard/project/tbijzvtyyewhtwgakgka
2. Settings > API > Service Role Key
3. Copiar la clave que empieza con `eyJhbGci...`

### **2. EPAYCO (SISTEMA DE PAGOS) 💳**

```bash
# Claves ePayco (YA CONFIGURADAS)
VITE_EPAYCO_PUBLIC_KEY=a04d60e2e678d5bd89a58d26f3413fdb
VITE_EPAYCO_PRIVATE_KEY=83ec651809bb7d11fcd114b16777bfa1
VITE_EPAYCO_CUSTOMER_ID=37257

# 🚨 IMPORTANTE: Modo de prueba
VITE_EPAYCO_TEST_MODE=true  # Cambiar a 'false' en producción final
```

### **3. APLICACIÓN 🌐**

```bash
# URL de la aplicación desplegada
VITE_APP_URL=https://tu-dominio-final.com

# Entorno de Node.js
NODE_ENV=production
```

---

## 🚀 CONFIGURACIÓN POR PLATAFORMA

### **EASYPANEL**
1. Ir a Project Settings > Environment Variables
2. Agregar cada variable una por una
3. Deploy automático al guardar

### **HEROKU**
```bash
# Via CLI
heroku config:set VITE_SUPABASE_URL=https://tbijzvtyyewhtwgakgka.supabase.co
heroku config:set VITE_SUPABASE_ANON_KEY=eyJhbGci...
heroku config:set VITE_SUPABASE_SERVICE_ROLE_KEY=tu_service_key
heroku config:set VITE_EPAYCO_PUBLIC_KEY=a04d60e2e678d5bd89a58d26f3413fdb
heroku config:set VITE_EPAYCO_PRIVATE_KEY=83ec651809bb7d11fcd114b16777bfa1
heroku config:set VITE_EPAYCO_CUSTOMER_ID=37257
heroku config:set VITE_EPAYCO_TEST_MODE=true
heroku config:set VITE_APP_URL=https://tu-app.herokuapp.com
heroku config:set NODE_ENV=production
```

### **VERCEL**
1. Ir a Project Settings > Environment Variables
2. Agregar cada variable con su valor
3. Redeploy automático

### **NETLIFY**
1. Site Settings > Environment Variables
2. Agregar todas las variables
3. Redeploy manual

---

## 📁 ARCHIVO .env LOCAL (DESARROLLO)

Crear en la raíz del proyecto:

```bash
# .env (NO subir a Git)
VITE_SUPABASE_URL=https://tbijzvtyyewhtwgakgka.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NTQyNjIsImV4cCI6MjA1ODUzMDI2Mn0.P09L8OpLpcrm5XzTLAN0oQllhl_bePk5bxbUUpoG-cQ
VITE_SUPABASE_SERVICE_ROLE_KEY=TU_SERVICE_KEY_AQUI
VITE_EPAYCO_PUBLIC_KEY=a04d60e2e678d5bd89a58d26f3413fdb
VITE_EPAYCO_PRIVATE_KEY=83ec651809bb7d11fcd114b16777bfa1
VITE_EPAYCO_CUSTOMER_ID=37257
VITE_EPAYCO_TEST_MODE=true
VITE_APP_URL=http://localhost:5173
NODE_ENV=development
```

---

## 🔄 TRANSICIÓN A PRODUCCIÓN

### **Cambios Críticos para Producción:**

1. **ePayco en modo real:**
```bash
VITE_EPAYCO_TEST_MODE=false
```

2. **URL real de la aplicación:**
```bash
VITE_APP_URL=https://academia-vallenata.com
```

3. **Node en producción:**
```bash
NODE_ENV=production
```

### **Verificación de Variables:**

Comprobar en tu aplicación desplegada:
- Página de administrador carga correctamente
- Sistema de pagos funciona
- Simulador carga sin errores
- Usuarios pueden registrarse

---

## 🚨 SEGURIDAD

### **Variables Públicas (Seguras en frontend):**
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_EPAYCO_PUBLIC_KEY`
- `VITE_EPAYCO_CUSTOMER_ID`
- `VITE_APP_URL`

### **Variables Sensibles (Solo servidor):**
- `VITE_SUPABASE_SERVICE_ROLE_KEY` ⚠️
- `VITE_EPAYCO_PRIVATE_KEY` ⚠️

**IMPORTANTE:** Las variables VITE_ son públicas en el bundle final. Solo pon datos sensibles si es absolutamente necesario.

---

## ✅ CHECKLIST DE CONFIGURACIÓN

- [ ] SERVICE_ROLE_KEY obtenida de Supabase
- [ ] Todas las variables configuradas en plataforma
- [ ] URL de aplicación actualizada
- [ ] Modo ePayco configurado (test/prod)
- [ ] Build exitoso con variables
- [ ] Funcionalidades básicas probadas

---

## 📞 SOPORTE

Si tienes problemas:
1. Verificar que todas las variables estén configuradas
2. Revisar logs de build/deploy
3. Probar en modo desarrollo local primero
4. Verificar conectividad con Supabase

**Tu proyecto está 95% listo. Solo falta la SERVICE_ROLE_KEY y configurar el dominio final.** 