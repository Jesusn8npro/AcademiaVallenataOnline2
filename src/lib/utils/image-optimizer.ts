// 🖼️ OPTIMIZADOR DE IMÁGENES NEXT-GEN
// Convierte imágenes a WebP/AVIF para móviles

export interface ImageConfig {
  src: string;
  alt: string;
  width?: number;
  height?: number;
  quality?: number;
  priority?: boolean;
  lazy?: boolean;
}

export function generateNextGenSrc(src: string, format: 'webp' | 'avif' = 'webp'): string {
  if (!src) return src;
  
  // Si ya es WebP o AVIF, retornar tal como está
  if (src.includes('.webp') || src.includes('.avif')) {
    return src;
  }
  
  // Convertir extensión a next-gen
  const extension = src.split('.').pop();
  if (extension && ['jpg', 'jpeg', 'png'].includes(extension.toLowerCase())) {
    return src.replace(new RegExp(`\\.${extension}$`, 'i'), `.${format}`);
  }
  
  return src;
}

export function generateSrcSet(src: string, widths: number[] = [320, 640, 960, 1280]): string {
  if (!src) return '';
  
  const webpSrc = generateNextGenSrc(src, 'webp');
  const baseName = webpSrc.replace(/\.[^/.]+$/, '');
  const extension = webpSrc.split('.').pop() || 'webp';
  
  return widths
    .map(width => `${baseName}-${width}w.${extension} ${width}w`)
    .join(', ');
}

export function generateSizes(breakpoints: Record<string, string> = {
  '(max-width: 320px)': '320px',
  '(max-width: 640px)': '640px', 
  '(max-width: 960px)': '960px',
  '(max-width: 1280px)': '1280px'
}): string {
  return Object.entries(breakpoints)
    .map(([media, size]) => `${media} ${size}`)
    .join(', ');
}

// Lazy loading avanzado con Intersection Observer
export function createLazyLoader() {
  if (typeof window === 'undefined') return;
  
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target as HTMLImageElement;
        const src = img.dataset.src;
        const srcset = img.dataset.srcset;
        
        if (src) img.src = src;
        if (srcset) img.srcset = srcset;
        
        img.classList.remove('loading');
        img.classList.add('loaded');
        observer.unobserve(img);
      }
    });
  }, {
    rootMargin: '50px', // Cargar 50px antes de que sea visible
    threshold: 0.1
  });
  
  return observer;
}

// Utilidad para detectar soporte de formatos
export function supportsWebP(): Promise<boolean> {
  return new Promise(resolve => {
    const webP = new Image();
    webP.onload = webP.onerror = () => resolve(webP.height === 2);
    webP.src = 'data:image/webp;base64,UklGRjoAAABXRUJQVlA4IC4AAACyAgCdASoCAAIALmk0mk0iIiIiIgBoSygABc6WWgAA/veff/0PP8bA//LwYAAA';
  });
}

export function supportsAVIF(): Promise<boolean> {
  return new Promise(resolve => {
    const avif = new Image();
    avif.onload = avif.onerror = () => resolve(avif.height === 2);
    avif.src = 'data:image/avif;base64,AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUIAAADybWV0YQAAAAAAAAAoaGRscgAAAAAAAAAAcGljdAAAAAAAAAAAAAAAAGxpYmF2aWYAAAAADnBpdG0AAAAAAAEAAAAeaWxvYwAAAABEAAABAAEAAAABAAABGgAAAB0AAAAoaWluZgAAAAAAAQAAABppbmZlAgAAAAABAABhdjAxQ29sb3IAAAAAamlwcnAAAABLaXBjbwAAABRpc3BlAAAAAAAAAAIAAAACAAAAEHBpeGkAAAAAAwgICAAAAAxhdjFDgQ0MAAAAABNjb2xybmNseAACAAIAAYAAAAAXaXBtYQAAAAAAAAABAAEEAQKDBAAAACVtZGF0EgAKCBgABogQEAwgMg8f8D///8WfhwB8+ErK42A=';
  });
} 