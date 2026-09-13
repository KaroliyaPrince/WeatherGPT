import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';

interface WeatherOrb3DProps {
  condition?: string;
  className?: string;
}

export const WeatherOrb3D: React.FC<WeatherOrb3DProps> = ({
  condition = 'Partly Cloudy',
  className = '',
}) => {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    // Scene, Camera, Renderer
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(
      45,
      container.clientWidth / container.clientHeight,
      0.1,
      100
    );
    camera.position.z = 24;

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    container.appendChild(renderer.domElement);

    // Lights
    const ambient = new THREE.AmbientLight(0xffffff, 1.2);
    scene.add(ambient);

    const pointLight = new THREE.PointLight(0xfde047, 3, 50);
    pointLight.position.set(10, 10, 10);
    scene.add(pointLight);

    const orbGroup = new THREE.Group();
    scene.add(orbGroup);

    const condStr = (condition || '').toLowerCase();
    const isRain = condStr.includes('rain') || condStr.includes('storm');

    let sunCore: THREE.Mesh | null = null;
    let sunRays: THREE.Mesh | null = null;
    let cloudMesh: THREE.Group | null = null;
    let rainParticles: THREE.Points | null = null;

    if (!isRain) {
      // 3D Glowing Solar Orb with Ray Rings
      const sunGeo = new THREE.IcosahedronGeometry(6.2, 3);
      const sunMat = new THREE.MeshStandardMaterial({
        color: 0xf59e0b,
        emissive: 0xd97706,
        roughness: 0.2,
        metalness: 0.4,
        wireframe: false,
      });
      sunCore = new THREE.Mesh(sunGeo, sunMat);
      orbGroup.add(sunCore);

      const rayGeo = new THREE.TorusGeometry(8.5, 0.4, 16, 48);
      const rayMat = new THREE.MeshBasicMaterial({
        color: 0xfde047,
        wireframe: true,
        transparent: true,
        opacity: 0.6,
      });
      sunRays = new THREE.Mesh(rayGeo, rayMat);
      orbGroup.add(sunRays);
    } else {
      // 3D Cloud Cluster + Emitting Rain Drops
      cloudMesh = new THREE.Group();
      const puffMat = new THREE.MeshStandardMaterial({
        color: 0x93c5fd,
        emissive: 0x1e3a8a,
        roughness: 0.6,
      });

      const p1 = new THREE.Mesh(new THREE.SphereGeometry(3.8, 16, 16), puffMat);
      const p2 = new THREE.Mesh(new THREE.SphereGeometry(4.8, 16, 16), puffMat);
      p2.position.set(2.5, 0.8, 0);
      const p3 = new THREE.Mesh(new THREE.SphereGeometry(3.2, 16, 16), puffMat);
      p3.position.set(-2.8, -0.4, 0);

      cloudMesh.add(p1);
      cloudMesh.add(p2);
      cloudMesh.add(p3);
      orbGroup.add(cloudMesh);

      // Rain Particles under Cloud
      const dropCount = 60;
      const dropGeo = new THREE.BufferGeometry();
      const dropPos = new Float32Array(dropCount * 3);
      for (let i = 0; i < dropCount; i++) {
        dropPos[i * 3] = (Math.random() - 0.5) * 8;
        dropPos[i * 3 + 1] = (Math.random() - 0.5) * 6 - 4;
        dropPos[i * 3 + 2] = (Math.random() - 0.5) * 4;
      }
      dropGeo.setAttribute('position', new THREE.BufferAttribute(dropPos, 3));
      const dropMat = new THREE.PointsMaterial({
        size: 1.8,
        color: 0x60a5fa,
        transparent: true,
        opacity: 0.9,
      });
      rainParticles = new THREE.Points(dropGeo, dropMat);
      orbGroup.add(rainParticles);
    }

    // Mouse Tilt / Parallax
    let mouseX = 0;
    let mouseY = 0;
    const onMouseMove = (e: MouseEvent) => {
      const rect = container.getBoundingClientRect();
      mouseX = ((e.clientX - rect.left) / rect.width - 0.5) * 2;
      mouseY = -((e.clientY - rect.top) / rect.height - 0.5) * 2;
    };
    container.addEventListener('mousemove', onMouseMove);

    // Animation loop
    let frameId: number;
    let timer = new THREE.Timer();

    const animate = () => {
      frameId = requestAnimationFrame(animate);
      timer.update();
      const elapsed = timer.getElapsed();

      orbGroup.rotation.y += 0.012 + mouseX * 0.02;
      orbGroup.rotation.x = mouseY * 0.4 + Math.sin(elapsed) * 0.1;
      orbGroup.position.y = Math.sin(elapsed * 1.8) * 0.8;

      if (sunRays) {
        sunRays.rotation.z += 0.02;
        sunRays.rotation.x = Math.sin(elapsed) * 0.3;
      }

      if (rainParticles) {
        const pos = rainParticles.geometry.attributes.position.array as Float32Array;
        for (let i = 0; i < pos.length / 3; i++) {
          pos[i * 3 + 1] -= 0.18;
          if (pos[i * 3 + 1] < -8) {
            pos[i * 3 + 1] = -1;
          }
        }
        rainParticles.geometry.attributes.position.needsUpdate = true;
      }

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
      container.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(frameId);
      renderer.dispose();
      if (container.contains(renderer.domElement)) {
        container.removeChild(renderer.domElement);
      }
    };
  }, [condition]);

  return (
    <div 
      ref={containerRef} 
      className={`w-28 h-28 sm:w-36 sm:h-36 cursor-pointer flex-shrink-0 ${className}`}
      title={`3D Holographic Weather Object (${condition})`}
    />
  );
};
