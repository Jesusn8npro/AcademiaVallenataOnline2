# 🚀 DEPLOY NIXPACKS + EASYPANEL - Academia Vallenata Online

## ✅ CONFIGURACIÓN OPTIMIZADA COMPLETADA

Tu proyecto está **100% listo** para Nixpacks en Easypanel. Se eliminaron todos los conflictos de Docker.

---

## 📋 CONFIGURACIÓN ACTUAL (YA APLICADA)

### **nixpacks.toml** (Optimizado)
```toml
[phases.setup]
nixPkgs = ['nodejs-18_x', 'npm-9_x']

[phases.install]
cmd = 'npm ci --only=production=false'

[phases.build]
cmd = 'npm run build'

[start]
cmd = 'node build'
```

### **Archivos Eliminados:**
- ❌ `Dockerfile` (Eliminado)
- ❌ `Dockerfile.simple` (Eliminado)
- ❌ `.dockerignore` (Eliminado)
- ❌ `nixpacks.json` (Eliminado - causaba conflicto)

---

## 🎯 CONFIGURACIÓN EN EASYPANEL

### **1. Configuración que DEBES usar en Easypanel:**

**Fuente:** GitHub
- **Propietario:** JesusBnpro
- **Repositorio:** AcademiaVallenataOnline2
- **Rama:** main
- **Ruta de compilación:** / (raíz)

**Compilación:** Nixpacks ✅
- **Comando de instalación:** `npm ci`
- **Comando de compilación:** `npm run build`
- **Comando de inicio:** `node build`

### **2. Variables de Entorno CRÍTICAS:**

```bash
# SUPABASE (OBLIGATORIAS)
VITE_SUPABASE_URL=https://tbijzvtyyewhtwgakgka.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NTQyNjIsImV4cCI6MjA1ODUzMDI2Mn0.P09L8OpLpcrm5XzTLAN0oQllhl_bePk5bxbUUpoG-cQ
VITE_SUPABASE_SERVICE_ROLE_KEY=[OBTENER DE SUPABASE PANEL]

# EPAYCO (PAGOS)
VITE_EPAYCO_PUBLIC_KEY=a04d60e2e678d5bd89a58d26f3413fdb
VITE_EPAYCO_PRIVATE_KEY=83ec651809bb7d11fcd114b16777bfa1
VITE_EPAYCO_CUSTOMER_ID=37257
VITE_EPAYCO_TEST_MODE=true

# APLICACIÓN
VITE_APP_URL=https://tu-app.easypanel.host
NODE_ENV=production
```

---

## 🔥 PASOS PARA DEPLOY

### **1. En Easypanel (LO QUE ESTÁS HACIENDO):**

1. **Crear App desde GitHub ✅**
2. **Seleccionar Nixpacks ✅**
3. **Configurar variables de entorno** (ver arriba)
4. **Guardar y Deploy**

### **2. Configuración en el Panel:**

```
Fuente: GitHub
├── Repositorio: github.com/JesusBnpro/AcademiaVallenataOnline2
├── Rama: main
├── Compilación: Nixpacks
└── Puerto: 3000 (automático)
```

**Comandos (Automáticos gracias a nixpacks.toml):**
- Install: `npm ci`
- Build: `npm run build`
- Start: `node build`

---

## 🚨 SI EL DEPLOY FALLA

### **Errores Comunes y Soluciones:**

**1. Error de Build:**
```bash
# Verificar que las dependencias estén correctas
npm ci
npm run build
```

**2. Error de Start:**
```bash
# El comando debe ser exactamente:
node build
```

**3. Variables de Entorno faltantes:**
- Verificar que **TODAS** las variables estén configuradas
- Especialmente `VITE_SUPABASE_SERVICE_ROLE_KEY`

**4. Error de Port:**
- Easypanel maneja automáticamente el puerto
- No configurar PORT manualmente

---

## 🎯 VERIFICACIÓN POST-DEPLOY

### **Una vez desplegado, verificar:**

1. **App carga correctamente** ✅
2. **Login funciona** (Supabase conectado)
3. **Panel admin accesible**
4. **Simulador carga**
5. **No errores en consola**

### **URLs a probar:**
- `/` - Página principal
- `/administrador` - Panel admin
- `/simulador-de-acordeon` - Simulador
- `/comunidad` - Red social

---

## 🔍 DEBUGGING

### **Si algo no funciona:**

**1. Revisar logs en Easypanel:**
- Ir a tu app > Logs
- Buscar errores de build o runtime

**2. Variables de entorno:**
```bash
# Verificar que estén todas configuradas
console.log(import.meta.env.VITE_SUPABASE_URL)
```

**3. Conectividad Supabase:**
- Verificar que la URL sea accesible
- Verificar que las claves sean válidas

---

## 💡 OPTIMIZACIONES POST-DEPLOY

### **Una vez funcionando:**

1. **Configurar dominio personalizado**
2. **Activar SSL automático**
3. **Configurar analytics**
4. **Cambiar ePayco a modo producción**

---

## 🎵 RESUMEN

**Tu configuración Nixpacks está PERFECTA:**
- ✅ No conflictos con Docker
- ✅ `adapter-node` configurado
- ✅ Scripts de build correctos
- ✅ Comando de inicio optimizado
- ✅ Variables de entorno preparadas

**Solo necesitas:**
1. Configurar las variables de entorno en Easypanel
2. Hacer click en "Deploy"
3. ¡Listo! 🚀

**¿Algún error específico en el deploy? Compárteme los logs para ayudarte.** 