import React, { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { Globe, MapPin } from 'lucide-react';
import { useUserProfile } from '../../hooks/useUserProfile';

interface GlobeCity {
  name: string;
  country: string;
  lat: number;
  lon: number;
  tempC: number;
  condition: string;
  isCurrent?: boolean;
}

const CITIES: GlobeCity[] = [
  { name: 'Rajkot', country: 'India', lat: 22.3039, lon: 70.8022, tempC: 28, condition: 'Partly Cloudy', isCurrent: true },
  { name: 'Mumbai', country: 'India', lat: 19.076, lon: 72.8777, tempC: 30, condition: 'Thunderstorm' },
  { name: 'Ahmedabad', country: 'India', lat: 23.0225, lon: 72.5714, tempC: 31, condition: 'Heavy Rain' },
  { name: 'New York', country: 'USA', lat: 40.7128, lon: -74.006, tempC: 22, condition: 'Sunny' },
  { name: 'London', country: 'UK', lat: 51.5074, lon: -0.1278, tempC: 18, condition: 'Cloudy' },
  { name: 'Tokyo', country: 'Japan', lat: 35.6762, lon: 139.6503, tempC: 24, condition: 'Clear' },
  { name: 'Dubai', country: 'UAE', lat: 25.2048, lon: 55.2708, tempC: 38, condition: 'Hot & Sunny' },
  { name: 'Paris', country: 'France', lat: 48.8566, lon: 2.3522, tempC: 20, condition: 'Light Rain' },
];

export const WeatherGlobe3D: React.FC<{ className?: string }> = ({ className = '' }) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [selectedCity, setSelectedCity] = useState<GlobeCity>(CITIES[0]);
  const [isRotating, setIsRotating] = useState(true);
  const { formatTemp } = useUserProfile();

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    // --- Three.js Scene Setup ---
    const scene = new THREE.Scene();

    const camera = new THREE.PerspectiveCamera(
      45,
      container.clientWidth / container.clientHeight,
      0.1,
      1000
    );
    camera.position.z = 52;

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    container.appendChild(renderer.domElement);

    // --- Lights ---
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.8);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0x60a5fa, 2.0);
    dirLight.position.set(40, 20, 30);
    scene.add(dirLight);

    const backLight = new THREE.DirectionalLight(0x9333ea, 1.2);
    backLight.position.set(-40, -20, -30);
    scene.add(backLight);

    // --- Earth Globe Mesh (Wireframe & Atmospheric Shader) ---
    const globeGroup = new THREE.Group();
    scene.add(globeGroup);

    const globeRadius = 18;

    // Solid base sphere
    const sphereGeo = new THREE.SphereGeometry(globeRadius, 48, 48);
    const sphereMat = new THREE.MeshStandardMaterial({
      color: 0x0f172a,
      roughness: 0.7,
      metalness: 0.1,
    });
    const baseSphere = new THREE.Mesh(sphereGeo, sphereMat);
    globeGroup.add(baseSphere);

    // Tech Grid Wireframe Mesh
    const wireGeo = new THREE.SphereGeometry(globeRadius + 0.15, 32, 32);
    const wireMat = new THREE.MeshBasicMaterial({
      color: 0x3b82f6,
      wireframe: true,
      transparent: true,
      opacity: 0.22,
    });
    const wireSphere = new THREE.Mesh(wireGeo, wireMat);
    globeGroup.add(wireSphere);

    // Outer Glow Halo
    const haloGeo = new THREE.SphereGeometry(globeRadius + 1.2, 32, 32);
    const haloMat = new THREE.MeshBasicMaterial({
      color: 0x60a5fa,
      transparent: true,
      opacity: 0.15,
      side: THREE.BackSide,
    });
    const haloSphere = new THREE.Mesh(haloGeo, haloMat);
    globeGroup.add(haloSphere);

    // Convert Lat/Lon to 3D Cartesian coordinates on sphere
    const latLonToVector3 = (lat: number, lon: number, radius: number): THREE.Vector3 => {
      const phi = (90 - lat) * (Math.PI / 180);
      const theta = (lon + 180) * (Math.PI / 180);
      const x = -(radius * Math.sin(phi) * Math.cos(theta));
      const z = radius * Math.sin(phi) * Math.sin(theta);
      const y = radius * Math.cos(phi);
      return new THREE.Vector3(x, y, z);
    };

    // City Marker Pins & Pulsing Radar Rings
    const cityMarkers: { mesh: THREE.Mesh; ring: THREE.Mesh; city: GlobeCity }[] = [];

    CITIES.forEach((city) => {
      const pos = latLonToVector3(city.lat, city.lon, globeRadius + 0.4);

      // Core Pin
      const pinGeo = new THREE.SphereGeometry(city.isCurrent ? 0.9 : 0.65, 16, 16);
      const pinMat = new THREE.MeshBasicMaterial({
        color: city.isCurrent ? 0xef4444 : 0x38bdf8,
      });
      const pinMesh = new THREE.Mesh(pinGeo, pinMat);
      pinMesh.position.copy(pos);
      globeGroup.add(pinMesh);

      // Radar Ring
      const ringGeo = new THREE.RingGeometry(0.8, 1.2, 24);
      const ringMat = new THREE.MeshBasicMaterial({
        color: city.isCurrent ? 0xf87171 : 0x60a5fa,
        side: THREE.DoubleSide,
        transparent: true,
        opacity: 0.7,
      });
      const ringMesh = new THREE.Mesh(ringGeo, ringMat);
      ringMesh.position.copy(pos);
      ringMesh.lookAt(new THREE.Vector3(0, 0, 0));
      globeGroup.add(ringMesh);

      cityMarkers.push({ mesh: pinMesh, ring: ringMesh, city });
    });

    // --- Interactive Mouse Drag to Rotate ---
    let isDragging = false;
    let previousMousePosition = { x: 0, y: 0 };

    const onMouseDown = (e: MouseEvent) => {
      isDragging = true;
      previousMousePosition = { x: e.clientX, y: e.clientY };
    };

    const onMouseMove = (e: MouseEvent) => {
      if (!isDragging) return;
      const deltaX = e.clientX - previousMousePosition.x;
      const deltaY = e.clientY - previousMousePosition.y;

      globeGroup.rotation.y += deltaX * 0.005;
      globeGroup.rotation.x += deltaY * 0.005;

      previousMousePosition = { x: e.clientX, y: e.clientY };
    };

    const onMouseUp = () => {
      isDragging = false;
    };

    const domEl = renderer.domElement;
    domEl.addEventListener('mousedown', onMouseDown);
    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('mouseup', onMouseUp);

    // --- Animation Loop ---
    let animationFrameId: number;
    let timer = new THREE.Timer();

    const animate = () => {
      animationFrameId = requestAnimationFrame(animate);
      timer.update();
      const elapsed = timer.getElapsed();

      // Auto rotation when not dragging
      if (!isDragging && isRotating) {
        globeGroup.rotation.y += 0.004;
      }

      // Animate pulsing radar rings
      cityMarkers.forEach(({ ring }, idx) => {
        const scale = 1 + Math.sin(elapsed * 4 + idx) * 0.35;
        ring.scale.set(scale, scale, scale);
      });

      renderer.render(scene, camera);
    };

    animate();

    // --- Resize ---
    const handleResize = () => {
      if (!container) return;
      camera.aspect = container.clientWidth / container.clientHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(container.clientWidth, container.clientHeight);
    };
    window.addEventListener('resize', handleResize);

    return () => {
      domEl.removeEventListener('mousedown', onMouseDown);
      window.removeEventListener('mousemove', onMouseMove);
      window.removeEventListener('mouseup', onMouseUp);
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(animationFrameId);

      sphereGeo.dispose();
      sphereMat.dispose();
      wireGeo.dispose();
      wireMat.dispose();
      haloGeo.dispose();
      haloMat.dispose();
      renderer.dispose();

      if (container.contains(renderer.domElement)) {
        container.removeChild(renderer.domElement);
      }
    };
  }, [isRotating]);

  return (
    <div className={`relative flex flex-col items-center justify-center rounded-3xl bg-gradient-to-b from-card/80 to-muted/50 border border-border p-5 shadow-2xl backdrop-blur-md overflow-hidden ${className}`}>
      {/* Header Info */}
      <div className="w-full flex items-center justify-between z-10 mb-2">
        <div className="flex items-center gap-2">
          <Globe className="w-5 h-5 text-primary animate-spin" style={{ animationDuration: '12s' }} />
          <div>
            <h3 className="text-sm font-bold text-foreground">3D Global Weather Radar</h3>
            <p className="text-[11px] text-muted-foreground">Drag to rotate and explore worldwide stations</p>
          </div>
        </div>

        <button
          onClick={() => setIsRotating(!isRotating)}
          className="px-2.5 py-1 text-xs font-semibold bg-primary/10 text-primary hover:bg-primary/20 rounded-lg transition-colors cursor-pointer"
        >
          {isRotating ? 'Pause Orbit' : 'Resume Orbit'}
        </button>
      </div>

      {/* 3D WebGL Canvas */}
      <div 
        ref={containerRef} 
        className="w-full h-64 sm:h-72 cursor-grab active:cursor-grabbing"
      />

      {/* Selected City Quick Info Card */}
      <div className="w-full flex flex-wrap items-center justify-between gap-3 p-3 bg-muted/70 rounded-2xl border border-border/80 z-10 mt-2">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-xl bg-primary text-primary-foreground">
            <MapPin className="w-4 h-4" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-foreground flex items-center gap-1.5">
              <span>{selectedCity.name}, {selectedCity.country}</span>
              {selectedCity.isCurrent && (
                <span className="px-1.5 py-0.2 rounded text-[9px] font-extrabold bg-red-500 text-white">LIVE</span>
              )}
            </h4>
            <p className="text-xs text-muted-foreground">{selectedCity.condition}</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-2xl font-black text-foreground">
            {formatTemp(selectedCity.tempC)}
          </span>
        </div>
      </div>

      {/* City Switcher Pills */}
      <div className="w-full flex items-center gap-1.5 overflow-x-auto py-2 z-10 mt-1 hide-scrollbar">
        {CITIES.map((city) => (
          <button
            key={city.name}
            onClick={() => setSelectedCity(city)}
            className={`px-3 py-1 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
              selectedCity.name === city.name
                ? 'bg-primary text-primary-foreground shadow-sm scale-105'
                : 'bg-background hover:bg-muted text-muted-foreground hover:text-foreground border border-border/60'
            }`}
          >
            {city.name} ({formatTemp(city.tempC)})
          </button>
        ))}
      </div>
    </div>
  );
};
