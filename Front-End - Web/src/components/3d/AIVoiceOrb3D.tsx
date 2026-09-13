import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';

interface AIVoiceOrb3DProps {
  state?: 'idle' | 'listening' | 'thinking' | 'speaking';
  className?: string;
}

export const AIVoiceOrb3D: React.FC<AIVoiceOrb3DProps> = ({
  state = 'idle',
  className = '',
}) => {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    // Scene
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(
      45,
      container.clientWidth / container.clientHeight,
      0.1,
      100
    );
    camera.position.z = 26;

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    container.appendChild(renderer.domElement);

    // Dynamic Colors based on Voice State
    let mainColor = 0x3b82f6; // blue
    let wireColor = 0x60a5fa;
    if (state === 'listening') {
      mainColor = 0x10b981; // green
      wireColor = 0x34d399;
    } else if (state === 'thinking') {
      mainColor = 0x8b5cf6; // purple
      wireColor = 0xa78bfa;
    } else if (state === 'speaking') {
      mainColor = 0xf59e0b; // amber / orange
      wireColor = 0xfcd34d;
    }

    // Orb Core
    const orbGroup = new THREE.Group();
    scene.add(orbGroup);

    // Inner glowing sphere
    const sphereGeo = new THREE.IcosahedronGeometry(6.5, 3);
    const sphereMat = new THREE.MeshStandardMaterial({
      color: mainColor,
      roughness: 0.3,
      metalness: 0.8,
      emissive: mainColor,
      emissiveIntensity: 0.35,
    });
    const sphereMesh = new THREE.Mesh(sphereGeo, sphereMat);
    orbGroup.add(sphereMesh);

    // Outer Audio Waveform Wireframe Rings
    const ringGeo1 = new THREE.TorusGeometry(8.8, 0.25, 16, 64);
    const ringMat1 = new THREE.MeshBasicMaterial({ color: wireColor, wireframe: true });
    const ring1 = new THREE.Mesh(ringGeo1, ringMat1);
    orbGroup.add(ring1);

    const ringGeo2 = new THREE.TorusGeometry(10.2, 0.18, 16, 64);
    const ringMat2 = new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.5 });
    const ring2 = new THREE.Mesh(ringGeo2, ringMat2);
    ring2.rotation.x = Math.PI / 2;
    orbGroup.add(ring2);

    // Atmospheric Lights
    const pointLight = new THREE.PointLight(mainColor, 3, 50);
    pointLight.position.set(0, 5, 10);
    scene.add(pointLight);

    const ambientLight = new THREE.AmbientLight(0xffffff, 0.9);
    scene.add(ambientLight);

    // Animation Loop
    let frameId: number;
    let timer = new THREE.Timer();

    const animate = () => {
      frameId = requestAnimationFrame(animate);
      timer.update();
      const elapsed = timer.getElapsed();

      // Dynamic oscillation based on voice state
      let speedMultiplier = 1.0;
      let pulseAmplitude = 0.08;

      if (state === 'listening') {
        speedMultiplier = 2.4;
        pulseAmplitude = 0.25;
      } else if (state === 'thinking') {
        speedMultiplier = 3.2;
        pulseAmplitude = 0.18;
      } else if (state === 'speaking') {
        speedMultiplier = 2.8;
        pulseAmplitude = 0.32;
      }

      orbGroup.rotation.y += 0.012 * speedMultiplier;
      orbGroup.rotation.x += 0.008 * speedMultiplier;

      const scale = 1 + Math.sin(elapsed * 4 * speedMultiplier) * pulseAmplitude;
      sphereMesh.scale.set(scale, scale, scale);

      ring1.rotation.z += 0.02 * speedMultiplier;
      ring2.rotation.y -= 0.015 * speedMultiplier;

      renderer.render(scene, camera);
    };

    animate();

    const handleResize = () => {
      if (!container) return;
      camera.aspect = container.clientWidth / container.clientHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(container.clientWidth, container.clientHeight);
    };
    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(frameId);
      sphereGeo.dispose();
      sphereMat.dispose();
      ringGeo1.dispose();
      ringMat1.dispose();
      ringGeo2.dispose();
      ringMat2.dispose();
      renderer.dispose();
      if (container.contains(renderer.domElement)) {
        container.removeChild(renderer.domElement);
      }
    };
  }, [state]);

  return (
    <div 
      ref={containerRef} 
      className={`w-32 h-32 sm:w-44 sm:h-44 ${className}`}
      title={`AI Neural Voice Sphere: State ${state}`}
    />
  );
};
