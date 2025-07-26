# 🚀 GUÍA DE DEPLOY SEGURO - ACADEMIA VALLENATA ONLINE

## ✅ **DEPLOY EXITOSO REALIZADO**
- **🌐 URL:** `https://academia-online-gamificacion-app-academia-vallenata-online.lnrubg.easypanel.host`
- **📅 Deploy exitoso:** 26 de Julio 2025
- **🔧 Plataforma:** EasyPanel con Nixpacks
- **⚙️ Framework:** SvelteKit + Node.js

---

## 🔧 **CONFIGURACIÓN EN EASYPANEL**

### **📦 FUENTE:**
```
Propietario: JesusN8npro
Repositorio: AcademiaVallenataOnline2
Rama: main
```

### **⚙️ COMPILACIÓN (Nixpacks):**
```bash
Comando de instalación: npm ci
Comando de compilación: npm run build
Comando de inicio: node build
Paquetes Nix: (vacío - auto-detectado)
Paquetes APT: (vacío)
```

---

## 🌍 **VARIABLES DE ENTORNO REQUERIDAS**

⚠️ **IMPORTANTE:** Configure estas variables en EasyPanel (Sección "Entorno"):

### **🔐 SUPABASE (Base de datos)**
```bash
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu_anon_key_aqui
VITE_SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key_aqui
```

### **💳 EPAYCO (Pagos)**
```bash
VITE_EPAYCO_PUBLIC_KEY=tu_public_key_aqui
VITE_EPAYCO_PRIVATE_KEY=tu_private_key_aqui
VITE_EPAYCO_CUSTOMER_ID=tu_customer_id
VITE_EPAYCO_TEST_MODE=true
```

### **🏗️ APLICACIÓN**
```bash
VITE_APP_URL=https://tu-dominio.easypanel.host/
NODE_ENV=production
```

---

## 🔍 **PROBLEMAS RESUELTOS**

### **🔴 PROBLEMA 1: Conflicto Deno/Node.js**
**Causa:** Carpeta `supabase/functions/` con código Deno confundía a Nixpacks
**✅ Solución:** Mover carpeta supabase fuera del proyecto

### **🔴 PROBLEMA 2: "vite: not found"**
**Causa:** Vite en devDependencies no se instalaba en producción
**✅ Solución:** Mover dependencias críticas a dependencies

### **🔴 PROBLEMA 3: Claves secretas expuestas**
**Causa:** Archivos con claves hardcodeadas en el repositorio
**✅ Solución:** Eliminar archivos y usar solo variables de entorno

---

## 📋 **CHECKLIST PARA FUTURO DEPLOY**

### **🔧 ANTES DEL DEPLOY:**
- [ ] Verificar que no hay claves hardcodeadas en el código
- [ ] Configurar todas las variables de entorno en EasyPanel
- [ ] Asegurar que `package.json` tiene dependencias correctas
- [ ] Verificar que no hay carpetas con código Deno en el proyecto

### **⚙️ CONFIGURACIÓN EASYPANEL:**
- [ ] Fuente: GitHub configurado correctamente
- [ ] Compilación: Nixpacks seleccionado
- [ ] Comandos: npm ci, npm run build, node build
- [ ] Variables de entorno: Todas configuradas
- [ ] Deploy: Implementar desde interfaz

### **✅ DESPUÉS DEL DEPLOY:**
- [ ] Verificar que la aplicación carga correctamente
- [ ] Probar funcionalidades críticas (auth, pagos)
- [ ] Verificar conectividad con Supabase
- [ ] Revisar logs en caso de errores

---

## 🚨 **MEDIDAS DE SEGURIDAD**

### **🔐 NUNCA INCLUIR EN EL CÓDIGO:**
- ❌ Claves de API reales
- ❌ Tokens de acceso
- ❌ Passwords de base de datos
- ❌ Claves privadas de pagos

### **✅ USAR SIEMPRE:**
- ✅ Variables de entorno
- ✅ Configuración en la plataforma de deploy
- ✅ Archivos .env.example sin valores reales
- ✅ .gitignore adecuado

---

## 📞 **SOPORTE**

Si encuentras problemas:
1. **Verificar logs** en EasyPanel
2. **Comprobar variables** de entorno
3. **Revisar configuración** de Nixpacks
4. **Contactar soporte** si persisten errores

---

**🎉 ¡Deploy completado exitosamente!** 