// ✅ NUEVO: Utilidades para manejo seguro de hidratación
// Este archivo centraliza todas las funciones relacionadas con la hidratación
// para evitar problemas de SSR → CSR en SvelteKit

import { browser } from '$app/environment';

/**
 * ✅ UTILIDAD: Verificar si estamos en el cliente de manera segura
 * @returns true si estamos en el cliente, false si estamos en SSR
 */
export function esCliente(): boolean {
  return browser;
}

/**
 * ✅ UTILIDAD: Ejecutar función solo en el cliente después de hidratación
 * @param fn Función a ejecutar
 * @param delay Delay en ms para asegurar hidratación completa (default: 100ms)
 */
export function ejecutarEnCliente(fn: () => void, delay: number = 100): void {
  if (!browser) return;
  
  setTimeout(() => {
    try {
      fn();
    } catch (error) {
      console.warn('⚠️ [HIDRATACIÓN] Error ejecutando función en cliente:', error);
    }
  }, delay);
}

/**
 * ✅ UTILIDAD: Aplicar clase CSS de manera segura
 * @param selector Selector CSS del elemento
 * @param className Nombre de la clase a aplicar
 */
export function aplicarClaseSegura(selector: string, className: string): void {
  if (!browser) return;
  
  try {
    const elementos = document.querySelectorAll(selector);
    elementos.forEach(el => {
      if (el instanceof HTMLElement) {
        el.classList.add(className);
      }
    });
  } catch (error) {
    console.warn('⚠️ [HIDRATACIÓN] Error aplicando clase:', error);
  }
}

/**
 * ✅ UTILIDAD: Remover clase CSS de manera segura
 * @param selector Selector CSS del elemento
 * @param className Nombre de la clase a remover
 */
export function removerClaseSegura(selector: string, className: string): void {
  if (!browser) return;
  
  try {
    const elementos = document.querySelectorAll(selector);
    elementos.forEach(el => {
      if (el instanceof HTMLElement) {
        el.classList.remove(className);
      }
    });
  } catch (error) {
    console.warn('⚠️ [HIDRATACIÓN] Error removiendo clase:', error);
  }
}

/**
 * ✅ UTILIDAD: Verificar si un elemento existe antes de manipularlo
 * @param selector Selector CSS del elemento
 * @returns true si el elemento existe, false en caso contrario
 */
export function elementoExiste(selector: string): boolean {
  if (!browser) return false;
  
  try {
    return document.querySelector(selector) !== null;
  } catch (error) {
    console.warn('⚠️ [HIDRATACIÓN] Error verificando elemento:', error);
    return false;
  }
}

/**
 * ✅ UTILIDAD: Esperar a que un elemento esté disponible
 * @param selector Selector CSS del elemento
 * @param timeout Timeout en ms (default: 5000ms)
 * @returns Promise que se resuelve cuando el elemento está disponible
 */
export function esperarElemento(selector: string, timeout: number = 5000): Promise<Element | null> {
  return new Promise((resolve) => {
    if (!browser) {
      resolve(null);
      return;
    }
    
    // Verificar si ya existe
    const elemento = document.querySelector(selector);
    if (elemento) {
      resolve(elemento);
      return;
    }
    
    // Esperar a que aparezca
    const observer = new MutationObserver((mutations) => {
      const elemento = document.querySelector(selector);
      if (elemento) {
        observer.disconnect();
        resolve(elemento);
      }
    });
    
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
    
    // Timeout de seguridad
    setTimeout(() => {
      observer.disconnect();
      resolve(null);
    }, timeout);
  });
}

/**
 * ✅ UTILIDAD: Crear un hook de hidratación segura
 * @param callback Función a ejecutar después de la hidratación
 * @param dependencies Dependencias que deben estar disponibles
 */
export function crearHookHidratacion(
  callback: () => void,
  dependencies: (() => boolean)[] = []
): void {
  if (!browser) return;
  
  // Verificar dependencias
  const dependenciasDisponibles = dependencies.every(dep => dep());
  if (!dependenciasDisponibles) {
    // Reintentar en el siguiente tick
    setTimeout(() => crearHookHidratacion(callback, dependencies), 50);
    return;
  }
  
  // Ejecutar callback
  ejecutarEnCliente(callback);
}

/**
 * ✅ UTILIDAD: Log de hidratación para debugging
 * @param mensaje Mensaje a loggear
 * @param datos Datos adicionales
 */
export function logHidratacion(mensaje: string, datos?: any): void {
  if (!browser) return;
  
  console.log(`🔧 [HIDRATACIÓN] ${mensaje}`, datos || '');
}

/**
 * ✅ UTILIDAD: Verificar estado de hidratación
 * @returns Objeto con información del estado de hidratación
 */
export function obtenerEstadoHidratacion(): {
  esCliente: boolean;
  esHidratado: boolean;
  timestamp: number;
} {
  return {
    esCliente: browser,
    esHidratado: browser && typeof window !== 'undefined',
    timestamp: Date.now()
  };
} 