import React, { useEffect, useMemo } from 'react';
import { MapContainer, TileLayer, Polyline, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { 
  NormalizedRouteSummary, 
  NormalizedRoutePlace 
} from '../../services/routeWeatherNormalizer';
import { decodePolyline } from '../../utils/polylineDecoder';
import { CloudOff } from 'lucide-react';

interface RouteMapLeafletProps {
  route: NormalizedRouteSummary;
  places: NormalizedRoutePlace[];
}

// Component to fit map bounds automatically when places/route change
function FitBounds({ points }: { points: [number, number][] }) {
  const map = useMap();

  useEffect(() => {
    if (points && points.length > 0) {
      const bounds = L.latLngBounds(points);
      map.fitBounds(bounds, { padding: [40, 40] });
    }
  }, [map, points]);

  return null;
}

// Custom DivIcons for Source, Destination, and Waypoints
const createCustomIcon = (type: 'source' | 'destination' | 'route_place', index: number) => {
  const bgClass = type === 'source' 
    ? 'bg-emerald-500 text-slate-950 ring-4 ring-emerald-500/30' 
    : type === 'destination' 
    ? 'bg-rose-500 text-white ring-4 ring-rose-500/30' 
    : 'bg-sky-500 text-slate-950 ring-2 ring-sky-500/20';

  const label = type === 'source' ? 'S' : type === 'destination' ? 'D' : (index + 1).toString();

  const html = `
    <div style="display:flex;align-items:center;justify-content:center;width:28px;height:28px;border-radius:9999px;font-weight:800;font-size:12px;box-shadow:0 4px 6px -1px rgba(0,0,0,0.3);border:2px solid #0f172a;" class="${bgClass}">
      ${label}
    </div>
  `;

  return L.divIcon({
    html,
    className: 'custom-leaflet-marker',
    iconSize: [28, 28],
    iconAnchor: [14, 14],
  });
};

export const RouteMapLeaflet: React.FC<RouteMapLeafletProps> = ({ route, places }) => {
  // Decode polyline string into coordinates
  const polylineCoords = useMemo(() => {
    let decoded = route.polyline ? decodePolyline(route.polyline) : [];
    
    // Fallback: If decoded polyline is empty, use place coordinates
    if (!decoded || decoded.length === 0) {
      decoded = places.map(p => [p.latitude, p.longitude] as [number, number]);
    }
    return decoded;
  }, [route.polyline, places]);

  const defaultCenter: [number, number] = polylineCoords.length > 0 
    ? polylineCoords[0] 
    : [22.8004, 70.8862];

  return (
    <div className="w-full h-80 sm:h-96 rounded-3xl overflow-hidden border border-white/20 shadow-2xl relative z-10">
      <MapContainer
        center={defaultCenter}
        zoom={8}
        scrollWheelZoom={false}
        className="w-full h-full"
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {/* Fit Bounds Helper */}
        <FitBounds points={polylineCoords} />

        {/* Polyline Route Line */}
        {polylineCoords.length > 1 && (
          <Polyline
            positions={polylineCoords}
            pathOptions={{ color: '#0284c7', weight: 5, opacity: 0.85, lineCap: 'round', lineJoin: 'round' }}
          />
        )}

        {/* Place Markers */}
        {places.map((place, idx) => {
          const icon = createCustomIcon(place.type, idx);
          const weather = place.weather;

          return (
            <Marker
              key={`${place.name}-${idx}`}
              position={[place.latitude, place.longitude]}
              icon={icon}
            >
              <Popup className="custom-leaflet-popup">
                <div className="p-1 space-y-1 text-slate-900 min-w-[150px]">
                  <div className="flex items-center justify-between gap-2 border-b pb-1">
                    <strong className="text-sm font-bold text-slate-900">{place.name}</strong>
                    <span className="text-[10px] uppercase font-bold text-slate-500">{place.type.replace('_', ' ')}</span>
                  </div>

                  {weather ? (
                    <div className="text-xs space-y-0.5 pt-0.5">
                      <div className="flex items-center justify-between">
                        <span className="font-semibold text-slate-700">{weather.condition.text}</span>
                        <strong className="text-sm text-sky-700 font-extrabold">{weather.temperatureC}°C</strong>
                      </div>
                      {weather.humidity !== undefined && (
                        <div className="text-[11px] text-slate-600">
                          Humidity: <strong>{weather.humidity}%</strong> • Wind: <strong>{weather.windSpeedKph || 0} km/h</strong>
                        </div>
                      )}
                      {weather.isStale && (
                        <div className="inline-flex items-center gap-1 text-[9px] font-bold px-1.5 py-0.5 rounded bg-amber-100 text-amber-800 border border-amber-300 mt-1">
                          <CloudOff className="w-2.5 h-2.5" /> Cached Weather
                        </div>
                      )}
                    </div>
                  ) : (
                    <p className="text-xs text-slate-500 italic">No weather data</p>
                  )}
                </div>
              </Popup>
            </Marker>
          );
        })}
      </MapContainer>
    </div>
  );
};
