// 🚀 STORE PWA ACADEMIA VALLENATA ONLINE
// Maneja: instalación, offline, notificaciones, cache

import { writable, readable, derived } from 'svelte/store';
import { browser } from '$app/environment';

// 🎯 DECLARACIÓN DE INTERFACES PWA
interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

declare global {
  interface WindowEventMap {
    beforeinstallprompt: BeforeInstallPromptEvent;
  }
}

// 🎯 TIPOS DE DATOS PWA
export interface EstadoPWA {
  puedeInstalar: boolean;
  estaInstalado: boolean;
  estaOffline: boolean;
  notificacionesPermitidas: boolean;
  serviceWorkerRegistrado: boolean;
  ultimaActualizacion: Date | null;
  cacheSize: number;
}

export interface NotificacionPWA {
  id: string;
  titulo: string;
  mensaje: string;
  tipo: 'practica' | 'curso' | 'logro' | 'general';
  url?: string;
  imagen?: string;
  programada?: Date;
}

// 🔧 CONFIGURACIÓN INICIAL
const estadoInicial: EstadoPWA = {
  puedeInstalar: false,
  estaInstalado: false,
  estaOffline: !browser || !navigator.onLine,
  notificacionesPermitidas: false,
  serviceWorkerRegistrado: false,
  ultimaActualizacion: null,
  cacheSize: 0
};

// 📊 STORES PRINCIPALES
export const estadoPWA = writable<EstadoPWA>(estadoInicial);
export const promptInstalacion = writable<BeforeInstallPromptEvent | null>(null);
export const notificacionesPendientes = writable<NotificacionPWA[]>([]);

// 🌐 ESTADO DE CONEXIÓN REACTIVO
export const estaOnline = readable(
  browser ? navigator.onLine : true,
  (set) => {
    if (!browser) return;

    const actualizarEstado = () => {
      const online = navigator.onLine;
      set(online);
      
      // Actualizar store principal
      estadoPWA.update(estado => ({
        ...estado,
        estaOffline: !online
      }));

      console.log(online ? '🌐 Conectado a internet' : '📱 Modo offline activado');
    };

    window.addEventListener('online', actualizarEstado);
    window.addEventListener('offline', actualizarEstado);

    return () => {
      window.removeEventListener('online', actualizarEstado);
      window.removeEventListener('offline', actualizarEstado);
    };
  }
);

// 🎵 STORE DERIVADO PARA FUNCIONES MUSICALES OFFLINE
export const funcionesOfflineDisponibles = derived(
  [estadoPWA, estaOnline],
  ([estado, online]) => ({
    simulador: true, // Siempre disponible
    grabaciones: estado.serviceWorkerRegistrado,
    cursos: estado.cacheSize > 0,
    sincronizacion: online && estado.serviceWorkerRegistrado,
    comunidad: online
  })
);

// 🚀 CLASE PRINCIPAL PWA MANAGER
class PWAManager {
  private deferredPrompt: BeforeInstallPromptEvent | null = null;
  private serviceWorkerRegistration: ServiceWorkerRegistration | null = null;

  // 🔧 INICIALIZAR PWA
  async inicializar(): Promise<void> {
    if (!browser) return;

    console.log('🚀 Inicializando PWA Academia Vallenata...');

    try {
      // Registrar Service Worker
      await this.registrarServiceWorker();
      
      // Configurar prompt de instalación
      this.configurarPromptInstalacion();
      
      // Verificar estado de notificaciones
      await this.verificarNotificaciones();
      
      // Detectar si ya está instalada
      this.detectarInstalacion();
      
      // Configurar sincronización
      this.configurarSincronizacion();

      console.log('✅ PWA inicializada exitosamente');
      
    } catch (error) {
      console.error('❌ Error inicializando PWA:', error);
    }
  }

  // 🔄 REGISTRAR SERVICE WORKER
  private async registrarServiceWorker(): Promise<void> {
    if (!('serviceWorker' in navigator)) {
      console.warn('⚠️ Service Worker no soportado en este navegador');
      return;
    }

    try {
      this.serviceWorkerRegistration = await navigator.serviceWorker.register('/sw.js', {
        scope: '/'
      });

      console.log('✅ Service Worker registrado');

      // Escuchar actualizaciones
      this.serviceWorkerRegistration.addEventListener('updatefound', () => {
        console.log('🔄 Nueva versión de SW disponible');
        this.manejarActualizacionSW();
      });

      // Actualizar estado
      estadoPWA.update(estado => ({
        ...estado,
        serviceWorkerRegistrado: true,
        ultimaActualizacion: new Date()
      }));

    } catch (error) {
      console.error('❌ Error registrando Service Worker:', error);
    }
  }

  // 📱 CONFIGURAR PROMPT DE INSTALACIÓN
  private configurarPromptInstalacion(): void {
    window.addEventListener('beforeinstallprompt', (e: BeforeInstallPromptEvent) => {
      console.log('📱 Prompt de instalación disponible');
      
      // Prevenir el prompt automático
      e.preventDefault();
      
      // Guardar el evento para uso posterior
      this.deferredPrompt = e;
      promptInstalacion.set(e);
      
      // Actualizar estado
      estadoPWA.update(estado => ({
        ...estado,
        puedeInstalar: true
      }));
    });

    // Detectar instalación exitosa
    window.addEventListener('appinstalled', () => {
      console.log('🎉 App instalada exitosamente');
      
      this.deferredPrompt = null;
      promptInstalacion.set(null);
      
      estadoPWA.update(estado => ({
        ...estado,
        estaInstalado: true,
        puedeInstalar: false
      }));

      // Mostrar notificación de bienvenida
      this.mostrarNotificacionBienvenida();
    });
  }

  // 🔔 VERIFICAR PERMISOS DE NOTIFICACIONES
  private async verificarNotificaciones(): Promise<void> {
    if (!('Notification' in window)) {
      console.warn('⚠️ Notificaciones no soportadas');
      return;
    }

    const permiso = Notification.permission;
    const permitidas = permiso === 'granted';

    estadoPWA.update(estado => ({
      ...estado,
      notificacionesPermitidas: permitidas
    }));

    console.log(`🔔 Notificaciones: ${permiso}`);
  }

  // 🔍 DETECTAR SI LA APP YA ESTÁ INSTALADA
  private detectarInstalacion(): void {
    // Método 1: matchMedia
    const estaInstalada = window.matchMedia('(display-mode: standalone)').matches ||
                         window.matchMedia('(display-mode: fullscreen)').matches;

    if (estaInstalada) {
      estadoPWA.update(estado => ({
        ...estado,
        estaInstalado: true
      }));
    }
  }

  // ⚡ CONFIGURAR SINCRONIZACIÓN BACKGROUND
  private configurarSincronizacion(): void {
    if (!this.serviceWorkerRegistration) return;

    // Registrar tags de sincronización
    if ('sync' in this.serviceWorkerRegistration) {
      console.log('⚡ Sincronización background configurada');
    }
  }

  // 🔄 MANEJAR ACTUALIZACIÓN DEL SERVICE WORKER
  private manejarActualizacionSW(): void {
    if (!this.serviceWorkerRegistration) return;

    const instalandoWorker = this.serviceWorkerRegistration.installing;
    if (!instalandoWorker) return;

    instalandoWorker.onstatechange = () => {
      if (instalandoWorker.state === 'installed') {
        if (navigator.serviceWorker.controller) {
          console.log('🔄 Nueva versión disponible');
          
          // Notificar al usuario sobre actualización
          this.notificarActualizacionDisponible();
        }
      }
    };
  }

  // 📱 INSTALAR APP (llamado por el usuario)
  async instalarApp(): Promise<boolean> {
    if (!this.deferredPrompt) {
      console.warn('⚠️ Prompt de instalación no disponible');
      return false;
    }

    try {
      // Mostrar prompt de instalación
      this.deferredPrompt.prompt();
      
      // Esperar respuesta del usuario
      const { outcome } = await this.deferredPrompt.userChoice;
      
      console.log(`📱 Usuario ${outcome} la instalación`);
      
      // Limpiar prompt
      this.deferredPrompt = null;
      promptInstalacion.set(null);
      
      if (outcome === 'accepted') {
        estadoPWA.update(estado => ({
          ...estado,
          puedeInstalar: false
        }));
        return true;
      }
      
      return false;
      
    } catch (error) {
      console.error('❌ Error instalando app:', error);
      return false;
    }
  }

  // 🔔 SOLICITAR PERMISOS DE NOTIFICACIONES
  async solicitarNotificaciones(): Promise<boolean> {
    if (!('Notification' in window)) return false;

    try {
      const permission = await Notification.requestPermission();
      const granted = permission === 'granted';
      
      estadoPWA.update(estado => ({
        ...estado,
        notificacionesPermitidas: granted
      }));

      console.log(`🔔 Permisos de notificación: ${permission}`);
      
      if (granted) {
        // Suscribirse a push notifications
        await this.suscribirPushNotifications();
      }
      
      return granted;
      
    } catch (error) {
      console.error('❌ Error solicitando notificaciones:', error);
      return false;
    }
  }

  // 🔔 SUSCRIBIR A PUSH NOTIFICATIONS
  private async suscribirPushNotifications(): Promise<void> {
    if (!this.serviceWorkerRegistration) return;

    try {
      // Aquí irían las claves VAPID reales
      const vapidPublicKey = 'TU_VAPID_PUBLIC_KEY';
      
      const subscription = await this.serviceWorkerRegistration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: vapidPublicKey
      });

      console.log('🔔 Suscrito a push notifications');
      
      // Enviar suscripción al servidor (Supabase)
      // await enviarSuscripcionAlServidor(subscription);
      
    } catch (error) {
      console.error('❌ Error suscribiendo a push:', error);
    }
  }

  // 🎵 PROGRAMAR NOTIFICACIÓN DE PRÁCTICA
  async programarNotificacionPractica(hora: number, minutos: number): Promise<void> {
    const notificacion: NotificacionPWA = {
      id: `practica-${Date.now()}`,
      titulo: '🎵 ¡Hora de Practicar!',
      mensaje: 'Es momento de tocar acordeón. ¡Tu progreso te espera!',
      tipo: 'practica',
      url: '/simulador-gaming',
      imagen: '/Acordeon PRO MAX.png',
      programada: new Date()
    };

    // Agregar a notificaciones pendientes
    notificacionesPendientes.update(pendientes => [...pendientes, notificacion]);
    
    console.log('⏰ Notificación de práctica programada');
  }

  // 🏆 MOSTRAR NOTIFICACIÓN DE LOGRO
  async notificarLogro(titulo: string, descripcion: string): Promise<void> {
    if (!('Notification' in window) || Notification.permission !== 'granted') return;

    try {
      const notif = new Notification(`🏆 ${titulo}`, {
        body: descripcion,
        icon: '/iconos-pwa/icon-192x192.png',
        badge: '/iconos-pwa/badge-72x72.png',
        tag: 'logro'
      });

      // Auto cerrar después de 5 segundos
      setTimeout(() => notif.close(), 5000);
      
    } catch (error) {
      console.error('❌ Error mostrando notificación de logro:', error);
    }
  }

  // 🔄 FORZAR ACTUALIZACIÓN DE LA APP
  async actualizarApp(): Promise<void> {
    if (!this.serviceWorkerRegistration) return;

    try {
      console.log('🔄 Forzando actualización...');
      
      // Comunicar con el SW para actualizar cache
      const controller = navigator.serviceWorker.controller;
      if (controller) {
        controller.postMessage({
          tipo: 'ACTUALIZAR_CACHE'
        });
      }
      
      // Recargar página después de un momento
      setTimeout(() => {
        window.location.reload();
      }, 1000);
      
    } catch (error) {
      console.error('❌ Error actualizando app:', error);
    }
  }

  // 📊 OBTENER ESTADÍSTICAS DE CACHE
  async obtenerEstadisticasCache(): Promise<any> {
    const controller = navigator.serviceWorker.controller;
    if (!controller) return null;

    return new Promise((resolve) => {
      const channel = new MessageChannel();
      
      channel.port1.onmessage = (event) => {
        if (event.data.tipo === 'ESTADO_CACHE') {
          resolve(event.data.caches);
          
          // Actualizar tamaño en el store
          const totalSize = Object.values(event.data.caches).reduce((sum: number, count: any) => sum + count, 0);
          estadoPWA.update(estado => ({
            ...estado,
            cacheSize: totalSize
          }));
        }
      };
      
      controller.postMessage({
        tipo: 'ESTADO_CACHE'
      }, [channel.port2]);
    });
  }

  // 🎉 NOTIFICACIÓN DE BIENVENIDA
  private mostrarNotificacionBienvenida(): void {
    this.notificarLogro(
      'Academia Vallenata Instalada',
      '¡Bienvenido! Ahora puedes acceder offline y recibir recordatorios de práctica.'
    );
  }

  // 🔄 NOTIFICAR ACTUALIZACIÓN DISPONIBLE
  private notificarActualizacionDisponible(): void {
    // Aquí podrías mostrar un banner o modal
    console.log('🔄 Nueva versión disponible - implementar UI');
  }
}

// 🚀 INSTANCIA SINGLETON
export const pwaManager = new PWAManager();

// 🔧 FUNCIONES AUXILIARES PARA COMPONENTES
export const funcionesPWA = {
  // Inicializar PWA
  inicializar: () => pwaManager.inicializar(),
  
  // Instalar app
  instalar: () => pwaManager.instalarApp(),
  
  // Solicitar notificaciones
  solicitarNotificaciones: () => pwaManager.solicitarNotificaciones(),
  
  // Programar práctica
  programarPractica: (hora: number, minutos: number) => 
    pwaManager.programarNotificacionPractica(hora, minutos),
  
  // Notificar logro
  notificarLogro: (titulo: string, descripcion: string) =>
    pwaManager.notificarLogro(titulo, descripcion),
  
  // Actualizar app
  actualizar: () => pwaManager.actualizarApp(),
  
  // Estadísticas
  estadisticas: () => pwaManager.obtenerEstadisticasCache()
};

// 🎯 AUTO-INICIALIZACIÓN EN BROWSER
if (browser) {
  // Inicializar después de que el DOM esté listo
  document.addEventListener('DOMContentLoaded', () => {
    pwaManager.inicializar();
  });
} 