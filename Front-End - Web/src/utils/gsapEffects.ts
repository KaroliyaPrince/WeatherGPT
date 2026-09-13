import { useEffect, useRef } from 'react';
import gsap from 'gsap';

/**
 * GSAP Magnetic Hover Effect Hook
 * Makes buttons and interactive elements smoothly follow the user's cursor
 * and snap back with a natural elastic spring easing.
 */
export function useMagnetic<T extends HTMLElement = HTMLButtonElement>(strength: number = 0.35) {
  const elementRef = useRef<T | null>(null);

  useEffect(() => {
    const el = elementRef.current;
    if (!el) return;

    const xTo = gsap.quickTo(el, 'x', { duration: 0.8, ease: 'elastic.out(1, 0.3)' });
    const yTo = gsap.quickTo(el, 'y', { duration: 0.8, ease: 'elastic.out(1, 0.3)' });

    const handleMouseMove = (e: MouseEvent) => {
      const { clientX, clientY } = e;
      const { left, top, width, height } = el.getBoundingClientRect();
      const x = (clientX - (left + width / 2)) * strength;
      const y = (clientY - (top + height / 2)) * strength;
      xTo(x);
      yTo(y);
    };

    const handleMouseLeave = () => {
      xTo(0);
      yTo(0);
    };

    el.addEventListener('mousemove', handleMouseMove);
    el.addEventListener('mouseleave', handleMouseLeave);

    return () => {
      el.removeEventListener('mousemove', handleMouseMove);
      el.removeEventListener('mouseleave', handleMouseLeave);
    };
  }, [strength]);

  return elementRef;
}

/**
 * GSAP Animated Counter Hook
 * Smoothly interpolates numeric values on change (e.g. temperatures, statistics)
 */
export function useGSAPCounter(value: number, duration: number = 0.8) {
  const textRef = useRef<HTMLSpanElement | null>(null);
  const prevValueRef = useRef(value);

  useEffect(() => {
    const el = textRef.current;
    if (!el) return;

    const obj = { val: prevValueRef.current };
    gsap.to(obj, {
      val: value,
      duration,
      ease: 'power2.out',
      onUpdate: () => {
        if (el) {
          el.innerText = Math.round(obj.val).toString();
        }
      },
    });

    prevValueRef.current = value;
  }, [value, duration]);

  return textRef;
}

/**
 * GSAP Glow Pulse Animation for radar and warning elements
 */
export function usePulseGlow(color: string = 'rgba(59, 130, 246, 0.6)') {
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const tween = gsap.to(el, {
      boxShadow: `0 0 25px ${color}`,
      repeat: -1,
      yoyo: true,
      duration: 1.5,
      ease: 'sine.inOut',
    });

    return () => {
      tween.kill();
    };
  }, [color]);

  return ref;
}
