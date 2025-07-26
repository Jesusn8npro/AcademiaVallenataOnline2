/**
 * Utilidades para el cursor personalizado
 * Funciones auxiliares y detección de capacidades del dispositivo
 */

export class UtilidadesCursor {
  
  /**
   * Detecta si el dispositivo es táctil (móvil/tablet)
   */
  static esDispositivoTactil(): boolean {
    // Múltiples métodos de detección para máxima compatibilidad
    
    // 1. Media query CSS hover: none
    const noTieneHover = window.matchMedia('(hover: none)').matches;
    
    // 2. Media query CSS pointer: coarse
    const pointerGrueso = window.matchMedia('(pointer: coarse)').matches;
    
    // 3. Detección táctil nativa
    const soportaToque = 'ontouchstart' in window || 
                        navigator.maxTouchPoints > 0 || 
                        (navigator as any).msMaxTouchPoints > 0;
    
    // 4. User Agent básico
    const userAgent = navigator.userAgent.toLowerCase();
    const esMovilUA = /android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(userAgent);
    
    // 5. Resolución de pantalla pequeña
    const pantallaPequena = window.innerWidth <= 768;
    
    // Es táctil si cumple múltiples condiciones
    const esTactil = (noTieneHover && pointerGrueso) || 
                     (soportaToque && pantallaPequena) || 
                     esMovilUA;
    
    return esTactil;
  }

  /**
   * Detecta si el navegador soporta mix-blend-mode
   */
  static soportaMixBlendMode(): boolean {
    try {
      const elemento = document.createElement('div');
      elemento.style.mixBlendMode = 'difference';
      return elemento.style.mixBlendMode === 'difference';
    } catch {
      return false;
    }
  }

  /**
   * Obtiene la posición relativa del mouse respecto a un elemento
   */
  static obtenerPosicionRelativa(evento: MouseEvent, elemento: HTMLElement): { x: number; y: number } {
    const rect = elemento.getBoundingClientRect();
    return {
      x: evento.clientX - rect.left,
      y: evento.clientY - rect.top
    };
  }

  /**
   * Calcula la distancia entre dos puntos
   */
  static calcularDistancia(x1: number, y1: number, x2: number, y2: number): number {
    return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
  }

  /**
   * Throttle function para optimizar performance
   */
  static throttle<T extends (...args: any[]) => any>(
    func: T, 
    limite: number
  ): (...args: Parameters<T>) => void {
    let ultimaLlamada = 0;
    return (...args: Parameters<T>) => {
      const ahora = Date.now();
      if (ahora - ultimaLlamada >= limite) {
        ultimaLlamada = ahora;
        func.apply(this, args);
      }
    };
  }

  /**
   * Debounce function para eventos que se disparan frecuentemente
   */
  static debounce<T extends (...args: any[]) => any>(
    func: T, 
    retraso: number
  ): (...args: Parameters<T>) => void {
    let timeoutId: number;
    return (...args: Parameters<T>) => {
      clearTimeout(timeoutId);
      timeoutId = window.setTimeout(() => func.apply(this, args), retraso);
    };
  }

  /**
   * Interpola suavemente entre dos valores
   */
  static interpolar(inicio: number, fin: number, factor: number): number {
    return inicio + (fin - inicio) * factor;
  }

  /**
   * Función de easing para animaciones suaves
   */
  static easeOutCubic(t: number): number {
    return 1 - Math.pow(1 - t, 3);
  }

  /**
   * Detecta si un elemento es visible en el viewport
   */
  static esElementoVisible(elemento: HTMLElement): boolean {
    const rect = elemento.getBoundingClientRect();
    return rect.top >= 0 && 
           rect.left >= 0 && 
           rect.bottom <= window.innerHeight && 
           rect.right <= window.innerWidth;
  }

  /**
   * Obtiene las propiedades CSS calculadas de un elemento
   */
  static obtenerEstilosComputados(elemento: HTMLElement): CSSStyleDeclaration {
    return window.getComputedStyle(elemento);
  }

  /**
   * Detecta si el cursor está sobre un elemento específico
   */
  static cursorSobreElemento(x: number, y: number, elemento: HTMLElement): boolean {
    const rect = elemento.getBoundingClientRect();
    return x >= rect.left && 
           x <= rect.right && 
           y >= rect.top && 
           y <= rect.bottom;
  }

  /**
   * Obtiene el elemento más específico bajo las coordenadas dadas
   */
  static obtenerElementoBajoCursor(x: number, y: number): HTMLElement | null {
    const elemento = document.elementFromPoint(x, y) as HTMLElement;
    return elemento || null;
  }

  /**
   * Detecta el tipo de elemento para aplicar contexto específico
   */
  static detectarTipoElemento(elemento: HTMLElement): string {
    if (!elemento) return 'normal';

    const tag = elemento.tagName.toLowerCase();
    const tipo = elemento.getAttribute('type')?.toLowerCase();
    const rol = elemento.getAttribute('role')?.toLowerCase();

    // Elementos de formulario
    if (tag === 'input') {
      if (['text', 'email', 'password', 'search'].includes(tipo || '')) {
        return 'texto';
      }
      if (['button', 'submit'].includes(tipo || '')) {
        return 'boton';
      }
    }

    if (tag === 'textarea' || elemento.contentEditable === 'true') {
      return 'texto';
    }

    // Elementos interactivos
    if (['button', 'a'].includes(tag) || rol === 'button') {
      return 'boton';
    }

    // Elementos arrastrables
    if (elemento.draggable || elemento.classList.contains('draggable')) {
      return 'arrastrable';
    }

    // Elementos con estados especiales
    if (elemento.classList.contains('cursor-hover') || 
        elemento.classList.contains('hover-especial')) {
      return 'especial';
    }

    return 'normal';
  }

  /**
   * Crea un efecto de partículas en una posición específica
   */
  static crearEfectoParticulas(x: number, y: number, opciones: {
    cantidad?: number;
    color?: string;
    duracion?: number;
  } = {}): void {
    const { cantidad = 6, color = '#6366f1', duracion = 800 } = opciones;

    for (let i = 0; i < cantidad; i++) {
      const particula = document.createElement('div');
      particula.style.cssText = `
        position: fixed;
        width: 4px;
        height: 4px;
        background-color: ${color};
        border-radius: 50%;
        pointer-events: none;
        z-index: 10000;
        left: ${x}px;
        top: ${y}px;
        opacity: 1;
      `;

      document.body.appendChild(particula);

      // Animación de la partícula
      const angulo = (i / cantidad) * Math.PI * 2;
      const distancia = 30 + Math.random() * 20;
      const finalX = x + Math.cos(angulo) * distancia;
      const finalY = y + Math.sin(angulo) * distancia;

      particula.animate([
        { 
          transform: `translate(0, 0) scale(1)`, 
          opacity: 1 
        },
        { 
          transform: `translate(${finalX - x}px, ${finalY - y}px) scale(0)`, 
          opacity: 0 
        }
      ], {
        duration: duracion,
        easing: 'cubic-bezier(0.25, 0.46, 0.45, 0.94)'
      }).addEventListener('finish', () => {
        document.body.removeChild(particula);
      });
    }
  }

  /**
   * Obtiene información del dispositivo para optimizaciones
   */
  static obtenerInfoDispositivo(): {
    esMovil: boolean;
    esTablet: boolean;
    esEscritorio: boolean;
    soportaHover: boolean;
    anchoVentana: number;
    altoVentana: number;
  } {
    const anchoVentana = window.innerWidth;
    const altoVentana = window.innerHeight;
    const soportaHover = window.matchMedia('(hover: hover)').matches;
    
    return {
      esMovil: anchoVentana < 768,
      esTablet: anchoVentana >= 768 && anchoVentana < 1024,
      esEscritorio: anchoVentana >= 1024,
      soportaHover,
      anchoVentana,
      altoVentana
    };
  }

  /**
   * Logs de debugging para desarrollo
   */
  static log(mensaje: string, datos?: any): void {
    if (import.meta.env?.DEV) {
      console.log(`🎯 Cursor: ${mensaje}`, datos || '');
    }
  }

  /**
   * Advertencias para desarrollo
   */
  static advertir(mensaje: string, datos?: any): void {
    if (import.meta.env?.DEV) {
      console.warn(`⚠️ Cursor: ${mensaje}`, datos || '');
    }
  }
} 