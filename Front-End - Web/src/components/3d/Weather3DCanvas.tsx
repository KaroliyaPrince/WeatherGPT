import React, { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { CloudRain, Sun, Cloud, Wind, Snowflake, Sparkles } from 'lucide-react';
import { motion } from 'motion/react';

export type Weather3DMode = 'rain' | 'sun' | 'clouds' | 'wind' | 'snow';

interface Weather3DCanvasProps {
  initialMode?: Weather3DMode;
  showControls?: boolean;
  className?: string;
  intensity?: number;
}

export const Weather3DCanvas: React.FC<Weather3DCanvasProps> = ({
  initialMode = 'rain',
  showControls = true,
  className = '',
  intensity = 1.0,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [activeMode, setActiveMode] = useState<Weather3DMode>(initialMode);
  const [is3DActive, setIs3DActive] = useState(true);

  // Sync mode with props if updated
  useEffect(() => {
    if (initialMode) {
      setActiveMode(initialMode);
    }
  }, [initialMode]);

  useEffect(() => {
    const container = containerRef.current;
    if (!container || !is3DActive) return;

    // --- Scene, Camera, Renderer ---
    const scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x0f172a, 0.002);

    const camera = new THREE.PerspectiveCamera(
      60,
      container.clientWidth / container.clientHeight,
      0.1,
      1000
    );
    camera.position.z = 80;

    const renderer = new THREE.WebGLRenderer({
      alpha: true,
      antialias: true,
      powerPreference: 'high-performance',
    });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.2;
    container.appendChild(renderer.domElement);

    // --- Lighting ---
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
    scene.add(ambientLight);

    const lightningLight = new THREE.PointLight(0x93c5fd, 0, 500);
    lightningLight.position.set(0, 100, 50);
    scene.add(lightningLight);

    const sunLight = new THREE.DirectionalLight(0xfef08a, 1.5);
    sunLight.position.set(50, 60, 40);
    scene.add(sunLight);

    // --- Mouse Parallax ---
    const mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
    const onMouseMove = (e: MouseEvent) => {
      const rect = container.getBoundingClientRect();
      const clientX = e.clientX - rect.left;
      const clientY = e.clientY - rect.top;
      mouse.targetX = (clientX / rect.width - 0.5) * 2;
      mouse.targetY = -(clientY / rect.height - 0.5) * 2;
    };
    window.addEventListener('mousemove', onMouseMove);

    // --- Dynamic Mode Objects ---
    let rainSystem: THREE.Points | null = null;
    let rainVelocities: Float32Array | null = null;
    let sunMesh: THREE.Mesh | null = null;
    let coronaMesh: THREE.Mesh | null = null;
    let sunParticles: THREE.Points | null = null;
    let cloudGroup: THREE.Group | null = null;
    let windParticles: THREE.Points | null = null;
    let snowSystem: THREE.Points | null = null;
    let lightningTimer = 0;

    // --- Mode 1: Rain & Thunderstorm ---
    if (activeMode === 'rain') {
      const rainCount = Math.floor(1800 * intensity);
      const rainGeometry = new THREE.BufferGeometry();
      const rainPositions = new Float32Array(rainCount * 3);
      rainVelocities = new Float32Array(rainCount);

      for (let i = 0; i < rainCount; i++) {
        rainPositions[i * 3] = (Math.random() - 0.5) * 250;
        rainPositions[i * 3 + 1] = (Math.random() - 0.5) * 160;
        rainPositions[i * 3 + 2] = (Math.random() - 0.5) * 160;
        rainVelocities[i] = 1.8 + Math.random() * 2.2;
      }
      rainGeometry.setAttribute('position', new THREE.BufferAttribute(rainPositions, 3));

      // Procedural soft elongated raindrop texture
      const canvas = document.createElement('canvas');
      canvas.width = 16;
      canvas.height = 64;
      const ctx = canvas.getContext('2d')!;
      const grad = ctx.createLinearGradient(8, 0, 8, 64);
      grad.addColorStop(0, 'rgba(255,255,255,0)');
      grad.addColorStop(0.5, 'rgba(147, 197, 253, 0.7)');
      grad.addColorStop(1, 'rgba(255, 255, 255, 0.95)');
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.ellipse(8, 32, 4, 30, 0, 0, Math.PI * 2);
      ctx.fill();
      const dropTexture = new THREE.CanvasTexture(canvas);

      const rainMaterial = new THREE.PointsMaterial({
        size: 2.8,
        map: dropTexture,
        transparent: true,
        opacity: 0.85,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      });

      rainSystem = new THREE.Points(rainGeometry, rainMaterial);
      scene.add(rainSystem);
    }

    // --- Mode 2: Sunny Rays & Solar Corona ---
    if (activeMode === 'sun') {
      // Sun Sphere Core
      const sunGeo = new THREE.SphereGeometry(14, 32, 32);
      const sunMat = new THREE.MeshBasicMaterial({
        color: 0xfbbf24,
      });
      sunMesh = new THREE.Mesh(sunGeo, sunMat);
      sunMesh.position.set(40, 25, -20);
      scene.add(sunMesh);

      // Sun Corona Halo
      const coronaGeo = new THREE.SphereGeometry(18, 32, 32);
      const coronaMat = new THREE.MeshBasicMaterial({
        color: 0xfde047,
        transparent: true,
        opacity: 0.35,
        wireframe: true,
      });
      coronaMesh = new THREE.Mesh(coronaGeo, coronaMat);
      coronaMesh.position.copy(sunMesh.position);
      scene.add(coronaMesh);

      // Heat Shimmer & Solar Dust Motes
      const moteCount = 350;
      const moteGeo = new THREE.BufferGeometry();
      const motePos = new Float32Array(moteCount * 3);
      for (let i = 0; i < moteCount; i++) {
        motePos[i * 3] = (Math.random() - 0.5) * 200;
        motePos[i * 3 + 1] = (Math.random() - 0.5) * 140;
        motePos[i * 3 + 2] = (Math.random() - 0.5) * 100;
      }
      moteGeo.setAttribute('position', new THREE.BufferAttribute(motePos, 3));
      const moteMat = new THREE.PointsMaterial({
        size: 2.2,
        color: 0xfef08a,
        transparent: true,
        opacity: 0.6,
        blending: THREE.AdditiveBlending,
      });
      sunParticles = new THREE.Points(moteGeo, moteMat);
      scene.add(sunParticles);
    }

    // --- Mode 3: Volumetric Drifting Clouds ---
    if (activeMode === 'clouds') {
      cloudGroup = new THREE.Group();
      const cloudCount = 28;
      const cloudMaterial = new THREE.MeshStandardMaterial({
        color: 0xe2e8f0,
        roughness: 0.9,
        transparent: true,
        opacity: 0.45,
      });

      for (let i = 0; i < cloudCount; i++) {
        const radius = 6 + Math.random() * 10;
        const sphereGeo = new THREE.SphereGeometry(radius, 16, 16);
        const cloudPuff = new THREE.Mesh(sphereGeo, cloudMaterial);
        cloudPuff.position.set(
          (Math.random() - 0.5) * 180,
          (Math.random() - 0.5) * 80 + 10,
          (Math.random() - 0.5) * 80 - 20
        );
        cloudPuff.scale.set(1.4 + Math.random() * 0.8, 0.7 + Math.random() * 0.4, 1);
        cloudGroup.add(cloudPuff);
      }
      scene.add(cloudGroup);
    }

    // --- Mode 4: Wind Gale & Particle Streamlines ---
    if (activeMode === 'wind') {
      const particleCount = 450;
      const windGeo = new THREE.BufferGeometry();
      const windPos = new Float32Array(particleCount * 3);
      for (let i = 0; i < particleCount; i++) {
        windPos[i * 3] = (Math.random() - 0.5) * 220;
        windPos[i * 3 + 1] = (Math.random() - 0.5) * 140;
        windPos[i * 3 + 2] = (Math.random() - 0.5) * 120;
      }
      windGeo.setAttribute('position', new THREE.BufferAttribute(windPos, 3));
      const windMat = new THREE.PointsMaterial({
        size: 3.5,
        color: 0x38bdf8,
        transparent: true,
        opacity: 0.65,
        blending: THREE.AdditiveBlending,
      });
      windParticles = new THREE.Points(windGeo, windMat);
      scene.add(windParticles);
    }

    // --- Mode 5: Snowfall ---
    if (activeMode === 'snow') {
      const snowCount = 1000;
      const snowGeo = new THREE.BufferGeometry();
      const snowPos = new Float32Array(snowCount * 3);
      for (let i = 0; i < snowCount; i++) {
        snowPos[i * 3] = (Math.random() - 0.5) * 220;
        snowPos[i * 3 + 1] = (Math.random() - 0.5) * 150;
        snowPos[i * 3 + 2] = (Math.random() - 0.5) * 120;
      }
      snowGeo.setAttribute('position', new THREE.BufferAttribute(snowPos, 3));
      const snowMat = new THREE.PointsMaterial({
        size: 3.0,
        color: 0xffffff,
        transparent: true,
        opacity: 0.8,
      });
      snowSystem = new THREE.Points(snowGeo, snowMat);
      scene.add(snowSystem);
    }

    // --- Animation Loop ---
    let animationFrameId: number;
    let timer = new THREE.Timer();

    const animate = () => {
      animationFrameId = requestAnimationFrame(animate);
      timer.update();
      const elapsedTime = timer.getElapsed();

      // Smooth mouse parallax damping
      mouse.x += (mouse.targetX - mouse.x) * 0.05;
      mouse.y += (mouse.targetY - mouse.y) * 0.05;

      camera.position.x = mouse.x * 12;
      camera.position.y = mouse.y * 8;
      camera.lookAt(0, 0, 0);

      // Animate Rain & Lightning
      if (rainSystem && rainVelocities) {
        const positions = rainSystem.geometry.attributes.position.array as Float32Array;
        for (let i = 0; i < rainVelocities.length; i++) {
          positions[i * 3 + 1] -= rainVelocities[i]; // Y fall
          positions[i * 3] += (mouse.x * 0.3) - 0.2; // Wind drift

          // Reset drop when hitting floor
          if (positions[i * 3 + 1] < -80) {
            positions[i * 3 + 1] = 80;
            positions[i * 3] = (Math.random() - 0.5) * 250;
          }
        }
        rainSystem.geometry.attributes.position.needsUpdate = true;

        // Dynamic Lightning Flashes
        lightningTimer += 0.016;
        if (lightningTimer > 4.5 && Math.random() < 0.035) {
          lightningLight.intensity = 8.0;
          lightningLight.position.x = (Math.random() - 0.5) * 80;
          lightningTimer = 0;
        } else if (lightningLight.intensity > 0) {
          lightningLight.intensity *= 0.82;
          if (lightningLight.intensity < 0.05) lightningLight.intensity = 0;
        }
      }

      // Animate Sun
      if (sunMesh && coronaMesh) {
        sunMesh.rotation.y += 0.005;
        coronaMesh.rotation.y -= 0.008;
        coronaMesh.rotation.z += 0.004;
        const scale = 1 + Math.sin(elapsedTime * 2) * 0.08;
        coronaMesh.scale.set(scale, scale, scale);
      }
      if (sunParticles) {
        sunParticles.rotation.y += 0.001;
        const pos = sunParticles.geometry.attributes.position.array as Float32Array;
        for (let i = 0; i < pos.length / 3; i++) {
          pos[i * 3 + 1] += Math.sin(elapsedTime + i) * 0.04;
        }
        sunParticles.geometry.attributes.position.needsUpdate = true;
      }

      // Animate Clouds
      if (cloudGroup) {
        cloudGroup.children.forEach((cloud, idx) => {
          cloud.position.x += 0.06 + (idx % 3) * 0.02;
          cloud.position.y += Math.sin(elapsedTime * 0.5 + idx) * 0.02;
          if (cloud.position.x > 110) {
            cloud.position.x = -110;
          }
        });
      }

      // Animate Wind
      if (windParticles) {
        const pos = windParticles.geometry.attributes.position.array as Float32Array;
        for (let i = 0; i < pos.length / 3; i++) {
          pos[i * 3] += 1.8 + Math.sin(pos[i * 3 + 1] * 0.05) * 0.8;
          pos[i * 3 + 1] += Math.sin(elapsedTime * 2 + i) * 0.3;
          if (pos[i * 3] > 120) {
            pos[i * 3] = -120;
            pos[i * 3 + 1] = (Math.random() - 0.5) * 140;
          }
        }
        windParticles.geometry.attributes.position.needsUpdate = true;
      }

      // Animate Snow
      if (snowSystem) {
        const pos = snowSystem.geometry.attributes.position.array as Float32Array;
        for (let i = 0; i < pos.length / 3; i++) {
          pos[i * 3 + 1] -= 0.4 + (i % 5) * 0.1;
          pos[i * 3] += Math.sin(elapsedTime + i) * 0.15;
          if (pos[i * 3 + 1] < -80) {
            pos[i * 3 + 1] = 80;
            pos[i * 3] = (Math.random() - 0.5) * 220;
          }
        }
        snowSystem.geometry.attributes.position.needsUpdate = true;
      }

      renderer.render(scene, camera);
    };

    animate();

    // --- Resize Listener ---
    const handleResize = () => {
      if (!container) return;
      camera.aspect = container.clientWidth / container.clientHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(container.clientWidth, container.clientHeight);
    };
    window.addEventListener('resize', handleResize);

    // --- Cleanup ---
    return () => {
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(animationFrameId);

      if (rainSystem) {
        rainSystem.geometry.dispose();
        (rainSystem.material as THREE.Material).dispose();
      }
      if (sunMesh) {
        sunMesh.geometry.dispose();
        (sunMesh.material as THREE.Material).dispose();
      }
      if (coronaMesh) {
        coronaMesh.geometry.dispose();
        (coronaMesh.material as THREE.Material).dispose();
      }
      if (sunParticles) {
        sunParticles.geometry.dispose();
        (sunParticles.material as THREE.Material).dispose();
      }
      if (cloudGroup) {
        cloudGroup.children.forEach((c) => {
          const m = c as THREE.Mesh;
          m.geometry.dispose();
          (m.material as THREE.Material).dispose();
        });
      }
      if (windParticles) {
        windParticles.geometry.dispose();
        (windParticles.material as THREE.Material).dispose();
      }
      if (snowSystem) {
        snowSystem.geometry.dispose();
        (snowSystem.material as THREE.Material).dispose();
      }

      renderer.dispose();
      if (container.contains(renderer.domElement)) {
        container.removeChild(renderer.domElement);
      }
    };
  }, [activeMode, is3DActive, intensity]);

  const presetButtons = [
    { mode: 'rain' as Weather3DMode, label: '3D Rain & Thunder', icon: CloudRain, color: 'text-blue-400' },
    { mode: 'sun' as Weather3DMode, label: '3D Solar Glow', icon: Sun, color: 'text-amber-400' },
    { mode: 'clouds' as Weather3DMode, label: '3D Cloud Drift', icon: Cloud, color: 'text-slate-300' },
    { mode: 'wind' as Weather3DMode, label: '3D Wind Gusts', icon: Wind, color: 'text-teal-300' },
    { mode: 'snow' as Weather3DMode, label: '3D Snowfall', icon: Snowflake, color: 'text-indigo-200' },
  ];

  return (
    <div className={`relative w-full h-full overflow-hidden ${className}`}>
      {/* 3D WebGL Canvas Layer */}
      <div 
        ref={containerRef} 
        className="absolute inset-0 pointer-events-none z-0 transition-opacity duration-700" 
      />

      {/* Floating 3D Atmosphere Control Pill (Optional) */}
      {showControls && (
        <div className="relative z-10 flex flex-wrap items-center justify-between gap-3 p-2.5 bg-background/60 backdrop-blur-md rounded-2xl border border-border/80 shadow-lg">
          <div className="flex items-center gap-2 px-2 text-xs font-bold text-foreground">
            <Sparkles className="w-4 h-4 text-primary animate-pulse" />
            <span className="hidden sm:inline">Interactive 3D Atmosphere:</span>
          </div>

          <div className="flex items-center gap-1.5 overflow-x-auto py-0.5">
            {presetButtons.map(({ mode, label, icon: Icon, color }) => (
              <motion.button
                key={mode}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => setActiveMode(mode)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                  activeMode === mode
                    ? 'bg-primary text-primary-foreground shadow-md'
                    : 'bg-muted/70 hover:bg-muted text-muted-foreground hover:text-foreground'
                }`}
                title={label}
              >
                <Icon className={`w-3.5 h-3.5 ${activeMode === mode ? 'text-primary-foreground' : color}`} />
                <span>{label.replace('3D ', '')}</span>
              </motion.button>
            ))}

            <button
              onClick={() => setIs3DActive(!is3DActive)}
              className="ml-1 px-2.5 py-1.5 text-[11px] font-bold rounded-lg border border-border/70 hover:bg-muted text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
              title="Toggle 3D WebGL Atmosphere"
            >
              {is3DActive ? '3D: ON' : '3D: OFF'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
